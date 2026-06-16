output "name" {
  description = "Logical name for this RBAC configuration."
  value       = var.name
}

output "identity_type" {
  description = "Configured principal type."
  value       = var.identity_type
}

output "principal_id" {
  description = "Object ID of the user-assigned identity, service principal, or existing principal."
  value       = local.principal_id
}

output "user_assigned_identity_id" {
  description = "User-assigned managed identity ID when created."
  value       = try(azurerm_user_assigned_identity.identity[0].id, null)
}

output "user_assigned_identity_client_id" {
  description = "User-assigned managed identity client ID when created."
  value       = try(azurerm_user_assigned_identity.identity[0].client_id, null)
}

output "user_assigned_identity_principal_id" {
  description = "User-assigned managed identity principal ID when created."
  value       = try(azurerm_user_assigned_identity.identity[0].principal_id, null)
}

output "application_id" {
  description = "Azure AD application (client) ID when a service principal is created."
  value       = try(azuread_application.app[0].client_id, null)
}

output "service_principal_id" {
  description = "Service principal object ID when created."
  value       = try(azuread_service_principal.sp[0].object_id, null)
}

output "custom_role_definition_ids" {
  description = "Custom role definition resource IDs keyed by logical name."
  value       = local.custom_role_definition_ids
}

output "role_assignment_ids" {
  description = "Role assignment IDs keyed by logical name."
  value       = { for key, assignment in azurerm_role_assignment.assignment : key => assignment.id }
}
