output "storage_account_id" {
  description = "ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "Primary blob host name."
  value       = azurerm_storage_account.this.primary_blob_host
}

output "primary_access_key" {
  description = "Primary access key. Null when shared_access_key_enabled is false."
  value       = var.shared_access_key_enabled ? azurerm_storage_account.this.primary_access_key : null
  sensitive   = true
}

output "container_names" {
  description = "Names of blob containers created by this module."
  value       = [for container in azurerm_storage_container.this : container.name]
}

output "network_rules_enabled" {
  description = "Whether network rules are configured."
  value       = var.network_rules != null
}

output "versioning_enabled" {
  description = "Whether blob versioning is enabled."
  value       = var.versioning_enabled
}

output "customer_managed_key_enabled" {
  description = "Whether customer-managed key encryption is enabled."
  value       = var.customer_managed_key != null
}
