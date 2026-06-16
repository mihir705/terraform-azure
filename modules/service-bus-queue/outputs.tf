output "namespace_id" {
  description = "Service Bus namespace ID."
  value       = local.namespace_id
}

output "namespace_name" {
  description = "Service Bus namespace name."
  value       = local.namespace_name
}

output "namespace_created" {
  description = "Whether this module created the namespace."
  value       = var.create_namespace
}

output "queue_id" {
  description = "Service Bus queue ID."
  value       = azurerm_servicebus_queue.queue.id
}

output "queue_name" {
  description = "Service Bus queue name."
  value       = azurerm_servicebus_queue.queue.name
}

output "dead_letter_enabled" {
  description = "Whether dead-lettering is configured via max_delivery_count."
  value       = var.create_dlq
}

output "max_delivery_count" {
  description = "Effective max delivery count before dead-lettering."
  value       = local.effective_max_delivery_count
}
