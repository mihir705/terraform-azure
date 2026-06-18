output "key_id" {
  description = "Versionless ID of the Key Vault key."
  value       = azurerm_key_vault_key.key.id
}

output "key_name" {
  description = "Name of the Key Vault key."
  value       = azurerm_key_vault_key.key.name
}

output "key_version" {
  description = "Current version of the Key Vault key."
  value       = azurerm_key_vault_key.key.version
}

output "key_resource_id" {
  description = "Full Azure resource ID of the key."
  value       = azurerm_key_vault_key.key.resource_id
}

output "key_vault_id" {
  description = "ID of the Key Vault containing the key."
  value       = local.key_vault_id
}

output "rotation_policy_enabled" {
  description = "Whether an automatic rotation policy is configured."
  value       = var.rotation_policy != null
}

output "key_type" {
  description = "Type of the Key Vault key."
  value       = azurerm_key_vault_key.key.key_type
}
