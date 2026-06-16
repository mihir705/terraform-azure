locals {
  vault_resource_group_name = try(
    var.vault_key.resource_group_name,
    var.resource_group_name
  )

  key_vault_id = coalesce(
    var.key_vault_id,
    try(data.azurerm_key_vault.vault[0].id, null)
  )
}

check "vault_reference_exclusive" {
  assert {
    condition     = (var.key_vault_id != null) != (var.vault_key != null)
    error_message = "Exactly one of key_vault_id or vault_key must be set."
  }
}

check "ec_key_size" {
  assert {
    condition     = !startswith(var.key_type, "EC") || var.key_size != null
    error_message = "key_size is required when key_type is EC or EC-HSM."
  }
}

data "azurerm_key_vault" "vault" {
  count = var.key_vault_id == null ? 1 : 0

  name                = var.vault_key.name
  resource_group_name = local.vault_resource_group_name
}

resource "azurerm_key_vault_key" "this" {
  name         = var.name
  key_vault_id = local.key_vault_id
  key_type     = var.key_type
  key_size     = var.key_size
  key_opts     = var.key_opts

  expiration_date = var.expiration_date
  not_before_date = var.not_before_date

  dynamic "rotation_policy" {
    for_each = var.rotation_policy != null ? [var.rotation_policy] : []

    content {
      expire_after         = try(rotation_policy.value.expire_after, null)
      notify_before_expiry = try(rotation_policy.value.notify_before_expiry, null)

      dynamic "automatic" {
        for_each = try(rotation_policy.value.automatic, null) != null ? [rotation_policy.value.automatic] : []

        content {
          time_before_expiry = automatic.value.time_before_expiry
        }
      }
    }
  }

  tags = var.tags
}
