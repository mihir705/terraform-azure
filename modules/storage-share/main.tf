data "azurerm_storage_account" "existing" {
  count = var.create_storage_account ? 0 : 1

  name                = var.existing_storage_account_name
  resource_group_name = coalesce(var.existing_storage_account_resource_group_name, var.resource_group_name)
}

locals {
  storage_account_id   = var.create_storage_account ? azurerm_storage_account.account[0].id : data.azurerm_storage_account.existing[0].id
  storage_account_name = var.create_storage_account ? azurerm_storage_account.account[0].name : data.azurerm_storage_account.existing[0].name
  storage_account_key  = var.create_storage_account ? azurerm_storage_account.account[0].primary_access_key : data.azurerm_storage_account.existing[0].primary_access_key
}

check "storage_account_name_required" {
  assert {
    condition     = !var.create_storage_account || (var.storage_account_name != null && var.storage_account_name != "")
    error_message = "storage_account_name is required when create_storage_account is true."
  }
}

check "existing_storage_account_required" {
  assert {
    condition     = var.create_storage_account || (var.existing_storage_account_name != null && var.existing_storage_account_name != "")
    error_message = "existing_storage_account_name is required when create_storage_account is false."
  }
}

resource "azurerm_storage_account" "account" {
  count = var.create_storage_account ? 1 : 0

  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"

  large_file_share_enabled = var.enable_large_file_share
  min_tls_version          = "TLS1_2"

  share_properties {
    retention_policy {
      days = 7
    }
  }

  tags = merge(var.tags, {
    Name = var.storage_account_name
  })
}

resource "azurerm_storage_share" "share" {
  name                 = var.name
  storage_account_name = local.storage_account_name
  quota                = var.quota_gb
  access_tier          = var.access_tier
  enabled_protocol     = var.enabled_protocol
  metadata             = length(var.metadata) > 0 ? var.metadata : null

  dynamic "acl" {
    for_each = var.acl

    content {
      id = acl.value.id

      dynamic "access_policy" {
        for_each = try(acl.value.access_policy, null) != null ? [acl.value.access_policy] : []

        content {
          permissions = access_policy.value.permissions
          start       = try(access_policy.value.start, null)
          expiry      = try(access_policy.value.expiry, null)
        }
      }
    }
  }
}

resource "azurerm_storage_share_directory" "directory" {
  for_each = var.directories

  name              = each.key
  storage_share_id  = azurerm_storage_share.share.id
}
