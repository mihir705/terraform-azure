output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group."
  value       = azurerm_resource_group.resource_group.id
}

output "location" {
  description = "Azure region of the resource group."
  value       = azurerm_resource_group.resource_group.location
}
