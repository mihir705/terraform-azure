output "service_id" {
  description = "API Management service ID."
  value       = azurerm_api_management.service.id
}

output "service_name" {
  description = "API Management service name."
  value       = azurerm_api_management.service.name
}

output "gateway_url" {
  description = "Gateway URL for the API Management service."
  value       = azurerm_api_management.service.gateway_url
}

output "gateway_regional_url" {
  description = "Regional gateway URL when applicable."
  value       = azurerm_api_management.service.gateway_regional_url
}

output "developer_portal_url" {
  description = "Developer portal URL."
  value       = azurerm_api_management.service.developer_portal_url
}

output "management_api_url" {
  description = "Management API URL."
  value       = azurerm_api_management.service.management_api_url
}

output "public_ip_addresses" {
  description = "Public IP addresses assigned to the service."
  value       = azurerm_api_management.service.public_ip_addresses
}

output "private_ip_addresses" {
  description = "Private IP addresses when VNet-integrated."
  value       = azurerm_api_management.service.private_ip_addresses
}

output "identity_principal_id" {
  description = "System-assigned managed identity principal ID when enabled."
  value       = try(azurerm_api_management.service.identity[0].principal_id, null)
}

output "api_ids" {
  description = "API resource IDs keyed by logical name."
  value       = { for key, api in azurerm_api_management_api.api : key => api.id }
}

output "operation_ids" {
  description = "Operation resource IDs keyed by logical name."
  value       = { for key, operation in azurerm_api_management_api_operation.operation : key => operation.id }
}

output "product_ids" {
  description = "Product IDs keyed by logical name."
  value       = { for key, product in azurerm_api_management_product.product : key => product.id }
}

output "backend_ids" {
  description = "Backend resource IDs keyed by logical name."
  value       = { for key, backend in azurerm_api_management_backend.backend : key => backend.id }
}
