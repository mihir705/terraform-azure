output "environment_id" {
  description = "Container Apps Environment ID."
  value       = azurerm_container_app_environment.this.id
}

output "environment_name" {
  description = "Container Apps Environment name."
  value       = azurerm_container_app_environment.this.name
}

output "default_domain" {
  description = "Default domain suffix for apps in the environment."
  value       = azurerm_container_app_environment.this.default_domain
}

output "static_ip_address" {
  description = "Static IP address for environment ingress."
  value       = azurerm_container_app_environment.this.static_ip_address
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID used by the environment."
  value       = local.log_analytics_workspace_id
}

output "container_app_ids" {
  description = "Container app IDs keyed by logical name."
  value       = { for name, app in azurerm_container_app.this : name => app.id }
}

output "container_app_fqdns" {
  description = "Container app FQDNs keyed by logical name."
  value       = { for name, app in azurerm_container_app.this : name => try(app.ingress[0].fqdn, null) }
}

output "latest_revision_names" {
  description = "Latest revision names keyed by container app logical name."
  value       = { for name, app in azurerm_container_app.this : name => app.latest_revision_name }
}
