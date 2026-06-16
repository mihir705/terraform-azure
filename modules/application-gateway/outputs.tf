output "application_gateway_id" {
  description = "Application Gateway resource ID."
  value       = azurerm_application_gateway.gateway.id
}

output "application_gateway_name" {
  description = "Application Gateway name."
  value       = azurerm_application_gateway.gateway.name
}

output "public_ip_address" {
  description = "Public IP address of the gateway. Null for internal gateways."
  value       = try(azurerm_public_ip.gateway[0].ip_address, null)
}

output "public_ip_id" {
  description = "Public IP resource ID. Null when using an existing IP or internal gateway."
  value       = coalesce(var.public_ip_address_id, try(azurerm_public_ip.gateway[0].id, null))
}

output "backend_pool_names" {
  description = "Backend address pool names keyed by target group key."
  value       = { for key, pool in var.target_groups : key => key }
}

output "listener_names" {
  description = "HTTP listener names keyed by listener key."
  value       = { for key, listener in var.listeners : key => key }
}
