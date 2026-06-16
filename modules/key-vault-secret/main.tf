locals {
  create_random_password = var.generate_random_password != null
  create_secret_value    = var.secret_value != null || local.create_random_password

  secret_value = local.create_random_password ? (
    try(var.generate_random_password.username, null) != null ? jsonencode({
      username = var.generate_random_password.username
      password = random_password.secret[0].result
    }) : random_password.secret[0].result
  ) : var.secret_value

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

check "secret_value_exclusive" {
  assert {
    condition = (
      (var.secret_value == null ? 0 : 1) +
      (var.generate_random_password == null ? 0 : 1)
    ) <= 1
    error_message = "Only one of secret_value or generate_random_password may be set."
  }
}

data "azurerm_key_vault" "vault" {
  count = var.key_vault_id == null ? 1 : 0

  name                = var.vault_key.name
  resource_group_name = local.vault_resource_group_name
}

resource "random_password" "secret" {
  count = local.create_random_password ? 1 : 0

  length           = var.generate_random_password.length
  special          = var.generate_random_password.special
  override_special = var.generate_random_password.override_special
}

resource "azurerm_key_vault_secret" "this" {
  count = local.create_secret_value && !var.ignore_secret_changes ? 1 : 0

  name         = var.name
  value        = local.secret_value
  key_vault_id = local.key_vault_id
  content_type = var.content_type

  expiration_date = var.expiration_date
  not_before_date = var.not_before_date

  tags = var.tags
}

resource "azurerm_key_vault_secret" "this_external" {
  count = local.create_secret_value && var.ignore_secret_changes ? 1 : 0

  name         = var.name
  value        = local.secret_value
  key_vault_id = local.key_vault_id
  content_type = var.content_type

  expiration_date = var.expiration_date
  not_before_date = var.not_before_date

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "shell" {
  count = local.create_secret_value ? 0 : 1

  name         = var.name
  value        = "placeholder-unset"
  key_vault_id = local.key_vault_id
  content_type = var.content_type

  expiration_date = var.expiration_date
  not_before_date = var.not_before_date

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}
