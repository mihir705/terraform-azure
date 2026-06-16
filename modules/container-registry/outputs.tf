output "registry_id" {
  description = "Container registry resource ID."
  value       = azurerm_container_registry.this.id
}

output "registry_name" {
  description = "Container registry name."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Registry login server URL."
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "Admin username when admin_enabled is true."
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_username : null
  sensitive   = true
}

output "admin_password" {
  description = "Admin password when admin_enabled is true."
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_password : null
  sensitive   = true
}

output "identity" {
  description = "Managed identity block for the registry."
  value       = azurerm_container_registry.this.identity
}
