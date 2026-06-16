data "azurerm_client_config" "current" {}

locals {
  tenant_id = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
}

check "rbac_access_policy_exclusive" {
  assert {
    condition     = var.enable_rbac_authorization || length(var.access_policies) > 0
    error_message = "When enable_rbac_authorization is false, at least one access_policy must be configured."
  }
}

check "access_policies_require_rbac_disabled" {
  assert {
    condition     = var.enable_rbac_authorization == false || length(var.access_policies) == 0
    error_message = "access_policies cannot be used when enable_rbac_authorization is true."
  }
}

resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = local.tenant_id
  sku_name            = var.sku_name

  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization

  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? [] : var.access_policies

    content {
      tenant_id = coalesce(access_policy.value.tenant_id, local.tenant_id)
      object_id = access_policy.value.object_id

      key_permissions         = try(access_policy.value.key_permissions, [])
      secret_permissions      = try(access_policy.value.secret_permissions, [])
      certificate_permissions = try(access_policy.value.certificate_permissions, [])
      storage_permissions     = try(access_policy.value.storage_permissions, [])
    }
  }

  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []

    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = try(network_acls.value.ip_rules, [])
      virtual_network_subnet_ids = try(network_acls.value.virtual_network_subnet_ids, [])
    }
  }

  tags = var.tags
}
