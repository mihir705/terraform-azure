output "profile_id" {
  description = "CDN profile ID."
  value       = azurerm_cdn_profile.profile.id
}

output "profile_name" {
  description = "CDN profile name."
  value       = azurerm_cdn_profile.profile.name
}

output "endpoint_id" {
  description = "CDN endpoint ID."
  value       = azurerm_cdn_endpoint.endpoint.id
}

output "endpoint_name" {
  description = "CDN endpoint name."
  value       = azurerm_cdn_endpoint.endpoint.name
}

output "endpoint_fqdn" {
  description = "CDN endpoint FQDN for public access."
  value       = azurerm_cdn_endpoint.endpoint.fqdn
}

output "endpoint_host_name" {
  description = "CDN endpoint host name."
  value       = azurerm_cdn_endpoint.endpoint.fqdn
}

output "origin_storage_account_id" {
  description = "Origin storage account ID."
  value       = local.origin_storage_account_id
}

output "origin_storage_account_name" {
  description = "Origin storage account name."
  value       = local.origin_storage_account_name
}

output "origin_storage_account_created" {
  description = "Whether this module created the origin storage account."
  value       = var.create_origin_storage_account
}

output "origin_host_name" {
  description = "Origin host name used by the CDN endpoint."
  value       = local.origin_host_name
}

output "custom_domain_ids" {
  description = "Custom domain resource IDs keyed by logical name."
  value       = { for key, domain in azurerm_cdn_endpoint_custom_domain.custom_domain : key => domain.id }
}
