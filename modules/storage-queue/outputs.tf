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

output "queue_id" {
  description = "Storage queue ID."
  value       = azurerm_storage_queue.queue.id
}

output "queue_name" {
  description = "Storage queue name."
  value       = azurerm_storage_queue.queue.name
}

output "queue_url" {
  description = "Storage queue URL."
  value       = "${local.storage_account_name}/${azurerm_storage_queue.queue.name}"
}
