output "profile_id" {
  description = "Front Door profile ID."
  value       = azurerm_cdn_frontdoor_profile.profile.id
}

output "profile_name" {
  description = "Front Door profile name."
  value       = azurerm_cdn_frontdoor_profile.profile.name
}

output "endpoint_id" {
  description = "Front Door endpoint ID."
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.id
}

output "endpoint_name" {
  description = "Front Door endpoint name."
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.name
}

output "endpoint_fqdn" {
  description = "Front Door endpoint FQDN for public access."
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
}

output "endpoint_host_name" {
  description = "Front Door endpoint host name."
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
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
  description = "Origin host name used by the Front Door origin."
  value       = local.origin_host_name
}

output "custom_domain_ids" {
  description = "Custom domain resource IDs keyed by logical name."
  value       = { for key, domain in azurerm_cdn_frontdoor_custom_domain.custom_domain : key => domain.id }
}
