locals {
  create_network_rules = var.network_rules != null
  create_lifecycle     = length(var.lifecycle_rules) > 0
  create_customer_key  = var.customer_managed_key != null
}

check "customer_key_requires_key_vault" {
  assert {
    condition     = local.create_customer_key == false || var.customer_managed_key.key_vault_key_id != null
    error_message = "customer_managed_key.key_vault_key_id is required when customer_managed_key is set."
  }
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  min_tls_version                   = var.min_tls_version
  allow_nested_items_to_be_public   = var.allow_nested_items_to_be_public
  shared_access_key_enabled         = var.shared_access_key_enabled
  https_traffic_only_enabled        = var.https_traffic_only_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  blob_properties {
    versioning_enabled  = var.versioning_enabled
    change_feed_enabled = var.change_feed_enabled

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }

  dynamic "customer_managed_key" {
    for_each = local.create_customer_key ? [var.customer_managed_key] : []

    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }

  dynamic "identity" {
    for_each = local.create_customer_key ? [1] : []

    content {
      type = "UserAssigned"
      identity_ids = [
        var.customer_managed_key.user_assigned_identity_id
      ]
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = try(each.value.access_type, "private")
  metadata              = try(each.value.metadata, null)
}

resource "azurerm_storage_account_network_rules" "this" {
  count = local.create_network_rules ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  default_action             = var.network_rules.default_action
  bypass                     = var.network_rules.bypass
  ip_rules                   = try(var.network_rules.ip_rules, [])
  virtual_network_subnet_ids = try(var.network_rules.virtual_network_subnet_ids, [])

  dynamic "private_link_access" {
    for_each = try(var.network_rules.private_link_access, [])

    content {
      endpoint_resource_id = private_link_access.value.endpoint_resource_id
      endpoint_tenant_id   = try(private_link_access.value.endpoint_tenant_id, null)
    }
  }
}

resource "azurerm_storage_management_policy" "this" {
  count = local.create_lifecycle ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        prefix_match = try(rule.value.filter.prefix_match, null)
        blob_types   = try(rule.value.filter.blob_types, ["blockBlob"])

        dynamic "match_blob_index_tag" {
          for_each = try(rule.value.filter.tags, [])

          content {
            name      = match_blob_index_tag.value.name
            operation = match_blob_index_tag.value.op
            value     = match_blob_index_tag.value.value
          }
        }
      }

      dynamic "actions" {
        for_each = [rule.value.actions]

        content {
          dynamic "base_blob" {
            for_each = try(actions.value.base_blob, null) != null ? [actions.value.base_blob] : []

            content {
              tier_to_cool_after_days_since_modification_greater_than    = try(base_blob.value.tier_to_cool_after_days, null)
              tier_to_archive_after_days_since_modification_greater_than = try(base_blob.value.tier_to_archive_after_days, null)
              delete_after_days_since_modification_greater_than          = try(base_blob.value.delete_after_days, null)
            }
          }

          dynamic "version" {
            for_each = try(actions.value.version, null) != null ? [actions.value.version] : []

            content {
              delete_after_days_since_creation = try(version.value.delete_after_days, null)
            }
          }

          dynamic "snapshot" {
            for_each = try(actions.value.snapshot, null) != null ? [actions.value.snapshot] : []

            content {
              delete_after_days_since_creation_greater_than = try(snapshot.value.delete_after_days, null)
            }
          }
        }
      }
    }
  }
}
