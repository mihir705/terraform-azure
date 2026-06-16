output "namespace_id" {
  description = "Event Hubs namespace ID."
  value       = azurerm_eventhub_namespace.namespace.id
}

output "namespace_name" {
  description = "Event Hubs namespace name."
  value       = azurerm_eventhub_namespace.namespace.name
}

output "event_hub_id" {
  description = "Event hub ID."
  value       = azurerm_eventhub.hub.id
}

output "event_hub_name" {
  description = "Event hub name."
  value       = azurerm_eventhub.hub.name
}

output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap server endpoint for the namespace."
  value       = "${azurerm_eventhub_namespace.namespace.name}.servicebus.windows.net:9093"
}

output "kafka_enabled" {
  description = "Whether Kafka protocol is supported for this namespace SKU."
  value       = local.kafka_enabled
}

output "consumer_group_names" {
  description = "Consumer group names keyed by logical name."
  value       = { for key, group in azurerm_eventhub_consumer_group.consumer_group : key => group.name }
}

output "consumer_group_ids" {
  description = "Consumer group IDs keyed by logical name."
  value       = { for key, group in azurerm_eventhub_consumer_group.consumer_group : key => group.id }
}
