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

output "topic_id" {
  description = "Service Bus topic ID."
  value       = azurerm_servicebus_topic.topic.id
}

output "topic_name" {
  description = "Service Bus topic name."
  value       = azurerm_servicebus_topic.topic.name
}

output "subscription_ids" {
  description = "Subscription IDs keyed by logical name."
  value       = { for key, subscription in azurerm_servicebus_subscription.subscription : key => subscription.id }
}

output "subscription_names" {
  description = "Subscription names keyed by logical name."
  value       = { for key, subscription in azurerm_servicebus_subscription.subscription : key => subscription.name }
}
