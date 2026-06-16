data "azurerm_storage_account" "existing" {
  count = var.create_storage_account ? 0 : 1

  name                = var.existing_storage_account_name
  resource_group_name = coalesce(var.existing_storage_account_resource_group_name, var.resource_group_name)
}

locals {
  storage_account_id   = var.create_storage_account ? azurerm_storage_account.account[0].id : data.azurerm_storage_account.existing[0].id
  storage_account_name = var.create_storage_account ? azurerm_storage_account.account[0].name : data.azurerm_storage_account.existing[0].name

  queue_name_tag = (
    var.name != null ? var.name :
    var.name_prefix != null ? "${var.name_prefix}-queue" :
    "storage-queue"
  )
}

check "name_exclusive" {
  assert {
    condition     = (var.name != null) != (var.name_prefix != null)
    error_message = "Exactly one of name or name_prefix must be set."
  }
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

  min_tls_version = "TLS1_2"

  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_queue" "queue" {
  name                 = coalesce(var.name, try("${var.name_prefix}-queue", null))
  storage_account_name = local.storage_account_name
  metadata             = length(var.metadata) > 0 ? var.metadata : null
}
