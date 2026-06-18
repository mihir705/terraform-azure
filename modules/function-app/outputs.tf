output "function_app_id" {
  description = "Function app resource ID."
  value       = local.function_app.id
}

output "function_app_name" {
  description = "Function app name."
  value       = local.function_app.name
}

output "default_hostname" {
  description = "Default hostname of the function app."
  value       = local.function_app.default_hostname
}

output "identity" {
  description = "Managed identity block for the function app."
  value       = local.function_app.identity
}

output "service_plan_id" {
  description = "App Service plan ID."
  value       = local.service_plan_id
}

output "storage_account_id" {
  description = "Storage account ID used by the function app."
  value       = local.storage_account_id
}

output "storage_account_name" {
  description = "Storage account name used by the function app."
  value       = local.storage_account_name
}

output "application_insights_id" {
  description = "Application Insights ID when created or referenced."
  value       = coalesce(var.application_insights_id, try(azurerm_application_insights.application_insights[0].id, null))
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key when created by the module."
  value       = try(azurerm_application_insights.application_insights[0].instrumentation_key, null)
  sensitive   = true
}

output "package_hash" {
  description = "Base64 SHA256 hash of the deployment package when built from package_source_dir."
  value       = try(data.archive_file.package[0].output_base64sha256, null)
}
