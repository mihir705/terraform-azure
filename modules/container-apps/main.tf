locals {
  log_analytics_workspace_name = coalesce(var.log_analytics_workspace_name, "${var.name}-law")
  log_analytics_workspace_id = var.log_analytics_workspace_id != null ? var.log_analytics_workspace_id : (
    length(azurerm_log_analytics_workspace.log_analytics) > 0 ? azurerm_log_analytics_workspace.log_analytics[0].id : null
  )
}

check "container_apps_required" {
  assert {
    condition     = length(var.container_apps) > 0
    error_message = "At least one container app is required."
  }
}

check "container_templates_required" {
  assert {
    condition = alltrue([
      for app in var.container_apps :
      length(app.template.containers) > 0
    ])
    error_message = "Each container app requires at least one container."
  }
}

check "key_vault_secret_identity" {
  assert {
    condition = alltrue([
      for app in var.container_apps : alltrue([
        for secret in coalesce(app.secrets, []) :
        secret.key_vault_secret_id == null || secret.identity != null
      ])
    ])
    error_message = "secrets with key_vault_secret_id require identity."
  }
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  count = var.create_log_analytics_workspace && var.log_analytics_workspace_id == null ? 1 : 0

  name                = local.log_analytics_workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(var.tags, {
    Name = local.log_analytics_workspace_name
  })
}

resource "azurerm_container_app_environment" "environment" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  infrastructure_subnet_id     = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.infrastructure_subnet_id != null ? var.internal_load_balancer_enabled : null
  zone_redundancy_enabled        = var.infrastructure_subnet_id != null ? var.zone_redundancy_enabled : null
  log_analytics_workspace_id     = local.log_analytics_workspace_id
  dapr_application_insights_connection_string = var.dapr_application_insights_connection_string

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "azurerm_container_app" "app" {
  for_each = var.container_apps

  name                         = each.key
  container_app_environment_id = azurerm_container_app_environment.environment.id
  resource_group_name          = var.resource_group_name
  revision_mode                = try(each.value.revision_mode, "Single")
  workload_profile_name        = try(each.value.workload_profile_name, null)

  dynamic "identity" {
    for_each = try(each.value.identity, null) != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "secret" {
    for_each = coalesce(try(each.value.secrets, null), [])

    content {
      name                = secret.value.name
      value               = try(secret.value.value, null)
      key_vault_secret_id = try(secret.value.key_vault_secret_id, null)
      identity            = try(secret.value.identity, null)
    }
  }

  dynamic "ingress" {
    for_each = try(each.value.ingress, null) != null ? [each.value.ingress] : []

    content {
      external_enabled           = try(ingress.value.external_enabled, true)
      target_port                = ingress.value.target_port
      transport                  = try(ingress.value.transport, "auto")
      allow_insecure_connections = try(ingress.value.allow_insecure_connections, false)

      dynamic "traffic_weight" {
        for_each = length(try(ingress.value.traffic_weight, [])) > 0 ? ingress.value.traffic_weight : [{ latest_revision = true, percentage = 100 }]

        content {
          label           = try(traffic_weight.value.label, null)
          latest_revision = try(traffic_weight.value.latest_revision, true)
          revision_suffix = try(traffic_weight.value.revision_suffix, null)
          percentage      = try(traffic_weight.value.percentage, 100)
        }
      }
    }
  }

  template {
    min_replicas = try(each.value.template.min_replicas, 0)
    max_replicas = try(each.value.template.max_replicas, 10)

    dynamic "container" {
      for_each = each.value.template.containers

      content {
        name    = container.value.name
        image   = container.value.image
        cpu     = try(container.value.cpu, 0.25)
        memory  = try(container.value.memory, "0.5Gi")
        args    = try(container.value.args, null)
        command = try(container.value.command, null)

        dynamic "env" {
          for_each = coalesce(try(container.value.env, null), [])

          content {
            name        = env.value.name
            value       = try(env.value.value, null)
            secret_name = try(env.value.secret_name, null)
          }
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = [
        for rule in coalesce(try(each.value.template.scale_rules, null), []) :
        rule if try(rule.http, null) != null
      ]

      content {
        name                = http_scale_rule.value.name
        concurrent_requests = try(http_scale_rule.value.http.concurrent_requests, null)
      }
    }

    dynamic "custom_scale_rule" {
      for_each = [
        for rule in coalesce(try(each.value.template.scale_rules, null), []) :
        rule if try(rule.custom, null) != null
      ]

      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom.type
        metadata         = custom_scale_rule.value.custom.metadata

        dynamic "authentication" {
          for_each = try(custom_scale_rule.value.custom.auth_secret_name, null) != null ? [custom_scale_rule.value.custom] : []

          content {
            secret_name       = authentication.value.auth_secret_name
            trigger_parameter = "connection"
          }
        }
      }
    }

    dynamic "azure_queue_scale_rule" {
      for_each = [
        for rule in coalesce(try(each.value.template.scale_rules, null), []) :
        rule if try(rule.azure_queue, null) != null
      ]

      content {
        name         = azure_queue_scale_rule.value.name
        queue_name   = azure_queue_scale_rule.value.azure_queue.queue_name
        queue_length = try(azure_queue_scale_rule.value.azure_queue.queue_length, 10)

        dynamic "authentication" {
          for_each = try(azure_queue_scale_rule.value.azure_queue.auth_secret_name, null) != null ? [azure_queue_scale_rule.value.azure_queue] : []

          content {
            secret_name       = authentication.value.auth_secret_name
            trigger_parameter = "connection"
          }
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = each.key
  })
}
