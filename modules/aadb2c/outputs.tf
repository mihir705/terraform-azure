output "directory_id" {
  description = "Azure AD B2C directory ID."
  value       = azurerm_aadb2c_directory.directory.id
}

output "tenant_id" {
  description = "Azure AD B2C tenant ID."
  value       = azurerm_aadb2c_directory.directory.tenant_id
}

output "domain_name" {
  description = "B2C tenant domain name (<prefix>.onmicrosoft.com)."
  value       = azurerm_aadb2c_directory.directory.domain_name
}

output "display_name" {
  description = "B2C tenant display name."
  value       = azurerm_aadb2c_directory.directory.display_name
}

output "billing_type" {
  description = "B2C tenant billing type."
  value       = azurerm_aadb2c_directory.directory.billing_type
}
