output "storage_account_id" {
  description = "Storage account ID."
  value       = local.storage_account_id
}

output "storage_account_name" {
  description = "Storage account name."
  value       = local.storage_account_name
}

output "storage_account_created" {
  description = "Whether this module created the storage account."
  value       = var.create_storage_account
}

output "share_id" {
  description = "Azure Files share ID."
  value       = azurerm_storage_share.share.id
}

output "share_name" {
  description = "Azure Files share name."
  value       = azurerm_storage_share.share.name
}

output "share_url" {
  description = "UNC-style share URL."
  value       = "//${local.storage_account_name}.file.core.windows.net/${azurerm_storage_share.share.name}"
}

output "mount_path" {
  description = "Suggested mount path for Linux clients."
  value       = "/mnt/${azurerm_storage_share.share.name}"
}

output "directory_ids" {
  description = "Share directory IDs keyed by logical name."
  value       = { for key, directory in azurerm_storage_share_directory.directory : key => directory.id }
}
