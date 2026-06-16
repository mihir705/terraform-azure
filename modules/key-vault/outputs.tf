output "key_vault_id" {
  description = "ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "tenant_id" {
  description = "Azure AD tenant ID used by the Key Vault."
  value       = azurerm_key_vault.this.tenant_id
}

output "rbac_authorization_enabled" {
  description = "Whether Azure RBAC authorization is enabled."
  value       = var.enable_rbac_authorization
}

output "purge_protection_enabled" {
  description = "Whether purge protection is enabled."
  value       = var.purge_protection_enabled
}

output "network_acls_enabled" {
  description = "Whether network ACLs are configured."
  value       = var.network_acls != null
}
