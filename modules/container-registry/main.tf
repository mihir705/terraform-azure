check "premium_features" {
  assert {
    condition = (
      var.sku == "Premium" ||
      (
        length(var.georeplications) == 0 &&
        var.network_rule_set == null &&
        var.retention_policy_in_days == null &&
        !var.trust_policy_enabled
      )
    )
    error_message = "georeplications, network_rule_set, retention_policy_in_days, and trust_policy_enabled require Premium SKU."
  }
}

resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  export_policy_enabled         = var.export_policy_enabled

  dynamic "retention_policy" {
    for_each = var.retention_policy_in_days != null ? [1] : []

    content {
      days = var.retention_policy_in_days
    }
  }

  dynamic "trust_policy" {
    for_each = var.trust_policy_enabled ? [1] : []

    content {
      enabled = true
    }
  }

  dynamic "network_rule_set" {
    for_each = var.network_rule_set != null ? [var.network_rule_set] : []

    content {
      default_action = try(network_rule_set.value.default_action, "Deny")

      dynamic "ip_rule" {
        for_each = coalesce(try(network_rule_set.value.ip_rules, null), [])

        content {
          action   = try(ip_rule.value.action, "Allow")
          ip_range = ip_rule.value.ip_range
        }
      }

      dynamic "virtual_network" {
        for_each = coalesce(try(network_rule_set.value.virtual_networks, null), [])

        content {
          action    = try(virtual_network.value.action, "Allow")
          subnet_id = virtual_network.value.subnet_id
        }
      }
    }
  }

  dynamic "georeplications" {
    for_each = var.georeplications

    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = try(georeplications.value.zone_redundancy_enabled, false)
      tags                    = try(georeplications.value.tags, var.tags)
    }
  }

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}
