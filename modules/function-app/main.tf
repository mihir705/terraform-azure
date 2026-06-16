resource "random_string" "storage_suffix" {
  count = var.storage_account_id == null && var.storage_account_name == null ? 1 : 0

  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

data "archive_file" "package" {
  count = var.package_source_dir != null ? 1 : 0

  type        = "zip"
  source_dir  = var.package_source_dir
  output_path = "${path.module}/.terraform/${var.name}-package.zip"
}

locals {
  is_linux       = var.os_type == "Linux"
  is_consumption = var.service_plan_sku == "Y1"

  default_storage_account_name = coalesce(
    var.storage_account_name,
    substr(replace("${var.name}sa${try(random_string.storage_suffix[0].result, "")}", "-", ""), 0, 24)
  )

  service_plan_name = coalesce(var.service_plan_name, "${var.name}-plan")
  application_insights_name = coalesce(var.application_insights_name, "${var.name}-ai")

  package_path = coalesce(
    var.package_path,
    try(data.archive_file.package[0].output_path, null)
  )

  merged_app_settings = merge(
    var.app_settings,
    var.create_application_insights && var.application_insights_id == null ? {
      APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this[0].connection_string
      APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.this[0].instrumentation_key
    } : {},
    var.application_insights_id != null && try(var.site_config.application_insights_connection_string, null) != null ? {
      APPLICATIONINSIGHTS_CONNECTION_STRING = var.site_config.application_insights_connection_string
    } : {},
    var.application_insights_id != null && try(var.site_config.application_insights_key, null) != null ? {
      APPINSIGHTS_INSTRUMENTATIONKEY = var.site_config.application_insights_key
    } : {}
  )
}

check "package_source_exclusive" {
  assert {
    condition     = var.package_source_dir == null || var.package_path == null
    error_message = "Use either package_source_dir or package_path, not both."
  }
}

check "storage_account_name_required" {
  assert {
    condition     = var.storage_account_id == null || var.storage_account_name != null
    error_message = "storage_account_name is required when storage_account_id is set."
  }
}
check "linux_runtime_required" {
  assert {
    condition     = !local.is_linux || (var.runtime_name != null && var.runtime_version != null)
    error_message = "Linux function apps require runtime_name and runtime_version."
  }
}

check "user_assigned_identity_ids" {
  assert {
    condition = (
      !contains(split(", ", replace(var.identity.type, ",", ",")), "UserAssigned") ||
      length(coalesce(var.identity.identity_ids, [])) > 0
    )
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned."
  }
}

resource "azurerm_service_plan" "this" {
  count = var.service_plan_id == null ? 1 : 0

  name                = local.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.service_plan_sku

  tags = merge(var.tags, {
    Name = local.service_plan_name
  })
}

resource "azurerm_storage_account" "this" {
  count = var.storage_account_id == null ? 1 : 0

  name                     = local.default_storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  min_tls_version          = "TLS1_2"

  tags = merge(var.tags, {
    Name = local.default_storage_account_name
  })
}

resource "azurerm_application_insights" "this" {
  count = var.create_application_insights && var.application_insights_id == null ? 1 : 0

  name                = local.application_insights_name
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "web"

  tags = merge(var.tags, {
    Name = local.application_insights_name
  })
}

data "azurerm_storage_account" "existing" {
  count = var.storage_account_id != null ? 1 : 0

  resource_group_name = var.resource_group_name
  name                = var.storage_account_name
}

locals {
  service_plan_id      = coalesce(var.service_plan_id, try(azurerm_service_plan.this[0].id, null))
  storage_account_id   = coalesce(var.storage_account_id, try(azurerm_storage_account.this[0].id, null))
  storage_account_name = coalesce(
    var.storage_account_name,
    local.default_storage_account_name,
    try(azurerm_storage_account.this[0].name, data.azurerm_storage_account.existing[0].name)
  )
  storage_uses_managed_identity = coalesce(var.storage_uses_managed_identity, var.storage_account_id != null)
  storage_account_access_key = local.storage_uses_managed_identity ? null : (
    var.storage_account_id == null ?
    azurerm_storage_account.this[0].primary_access_key :
    data.azurerm_storage_account.existing[0].primary_access_key
  )
}

resource "azurerm_linux_function_app" "this" {
  count = local.is_linux ? 1 : 0

  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = local.service_plan_id
  storage_account_name          = local.storage_account_name
  storage_account_access_key    = local.storage_account_access_key
  storage_uses_managed_identity = local.storage_uses_managed_identity

  functions_extension_version = var.functions_extension_version
  https_only                  = var.https_only
  public_network_access_enabled = var.public_network_access_enabled

  app_settings = local.merged_app_settings

  site_config {
    always_on                              = coalesce(try(var.site_config.always_on, null), !local.is_consumption)
    app_scale_limit                        = try(var.site_config.app_scale_limit, null)
    ftps_state                             = try(var.site_config.ftps_state, "Disabled")
    health_check_path                      = try(var.site_config.health_check_path, null)
    minimum_tls_version                    = try(var.site_config.minimum_tls_version, "1.2")
    pre_warmed_instance_count              = try(var.site_config.pre_warmed_instance_count, null)
    use_32_bit_worker                      = try(var.site_config.use_32_bit_worker, false)
    vnet_route_all_enabled                 = try(var.site_config.vnet_route_all_enabled, false)
    application_insights_connection_string = try(var.site_config.application_insights_connection_string, null)
    application_insights_key               = try(var.site_config.application_insights_key, null)

    dynamic "cors" {
      for_each = length(try(var.site_config.cors_allowed_origins, [])) > 0 ? [1] : []

      content {
        allowed_origins = var.site_config.cors_allowed_origins
      }
    }

    application_stack {
      dotnet_version              = var.runtime_name == "dotnet" ? var.runtime_version : null
      java_version                = var.runtime_name == "java" ? var.runtime_version : null
      node_version                = var.runtime_name == "node" ? var.runtime_version : null
      powershell_core_version     = var.runtime_name == "powershell" ? var.runtime_version : null
      python_version              = var.runtime_name == "python" ? var.runtime_version : null
      use_dotnet_isolated_runtime = var.runtime_name == "dotnet-isolated"
    }
  }

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  virtual_network_subnet_id = try(var.vnet_integration.subnet_id, null)

  zip_deploy_file = local.package_path

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

resource "azurerm_windows_function_app" "this" {
  count = local.is_linux ? 0 : 1

  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = local.service_plan_id
  storage_account_name          = local.storage_account_name
  storage_account_access_key    = local.storage_account_access_key
  storage_uses_managed_identity = local.storage_uses_managed_identity

  functions_extension_version = var.functions_extension_version
  https_only                  = var.https_only
  public_network_access_enabled = var.public_network_access_enabled

  app_settings = local.merged_app_settings

  site_config {
    always_on                              = coalesce(try(var.site_config.always_on, null), !local.is_consumption)
    app_scale_limit                        = try(var.site_config.app_scale_limit, null)
    ftps_state                             = try(var.site_config.ftps_state, "Disabled")
    health_check_path                      = try(var.site_config.health_check_path, null)
    minimum_tls_version                    = try(var.site_config.minimum_tls_version, "1.2")
    pre_warmed_instance_count              = try(var.site_config.pre_warmed_instance_count, null)
    use_32_bit_worker                      = try(var.site_config.use_32_bit_worker, false)
    vnet_route_all_enabled                 = try(var.site_config.vnet_route_all_enabled, false)
    application_insights_connection_string = try(var.site_config.application_insights_connection_string, null)
    application_insights_key               = try(var.site_config.application_insights_key, null)

    dynamic "cors" {
      for_each = length(try(var.site_config.cors_allowed_origins, [])) > 0 ? [1] : []

      content {
        allowed_origins = var.site_config.cors_allowed_origins
      }
    }

    dynamic "application_stack" {
      for_each = var.use_dotnet_isolated ? [1] : []

      content {
        dotnet_version              = var.dotnet_version
        use_dotnet_isolated_runtime = true
      }
    }
  }

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  virtual_network_subnet_id = try(var.vnet_integration.subnet_id, null)

  zip_deploy_file = local.package_path

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

locals {
  function_app = local.is_linux ? azurerm_linux_function_app.this[0] : azurerm_windows_function_app.this[0]
}
