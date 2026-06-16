variable "name" {
  description = "Function app name."
  type        = string

  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 60
    error_message = "name must be between 2 and 60 characters."
  }
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "os_type" {
  description = "Function app OS type: Linux or Windows."
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be Linux or Windows."
  }
}

variable "service_plan_id" {
  description = "Existing App Service plan ID. Created automatically when null."
  type        = string
  default     = null
}

variable "service_plan_name" {
  description = "App Service plan name when created by the module."
  type        = string
  default     = null
}

variable "service_plan_sku" {
  description = "App Service plan SKU. Use Y1 for consumption, EP1/EP2/EP3 for premium."
  type        = string
  default     = "Y1"

  validation {
    condition     = can(regex("^(Y1|EP[0-9]|P[0-9]v[0-9])", var.service_plan_sku))
    error_message = "service_plan_sku must be Y1 (consumption) or a premium/elastic premium SKU such as EP1."
  }
}

variable "storage_account_id" {
  description = "Existing storage account ID for the function app. Created automatically when null."
  type        = string
  default     = null
}

variable "storage_account_name" {
  description = "Storage account name. Required when storage_account_id is set; otherwise auto-generated when created by the module."
  type        = string
  default     = null
}

variable "storage_uses_managed_identity" {
  description = "Use managed identity for storage access. Defaults to true when storage_account_id is set."
  type        = bool
  default     = null
}

variable "storage_account_tier" {
  description = "Storage account tier."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier must be Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Storage account replication type."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_type must be a valid Azure replication type."
  }
}

variable "functions_extension_version" {
  description = "Functions runtime version."
  type        = string
  default     = "~4"
}

variable "runtime_name" {
  description = "Application stack runtime name (e.g. python, node, dotnet)."
  type        = string
  default     = null
}

variable "runtime_version" {
  description = "Application stack runtime version."
  type        = string
  default     = null
}

variable "dotnet_version" {
  description = "Dotnet version for Windows function apps."
  type        = string
  default     = null
}

variable "use_dotnet_isolated" {
  description = "Use .NET isolated worker runtime on Windows."
  type        = bool
  default     = false
}

variable "package_source_dir" {
  description = "Local directory to zip and deploy. Cannot be combined with package_path."
  type        = string
  default     = null
}

variable "package_path" {
  description = "Path to an existing zip deployment package. Cannot be combined with package_source_dir."
  type        = string
  default     = null
}

variable "app_settings" {
  description = "Function app settings."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "site_config" {
  description = "Additional site configuration overrides."
  type = object({
    always_on                              = optional(bool)
    app_scale_limit                        = optional(number)
    application_insights_connection_string = optional(string)
    application_insights_key               = optional(string)
    cors_allowed_origins                   = optional(list(string), [])
    ftps_state                             = optional(string, "Disabled")
    health_check_path                      = optional(string)
    minimum_tls_version                    = optional(string, "1.2")
    pre_warmed_instance_count              = optional(number)
    use_32_bit_worker                      = optional(bool, false)
    vnet_route_all_enabled                 = optional(bool, false)
  })
  default = {}
}

variable "identity" {
  description = "Managed identity configuration."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = {
    type = "SystemAssigned"
  }

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "vnet_integration" {
  description = "Regional VNet integration configuration."
  type = object({
    subnet_id = string
  })
  default = null
}

variable "application_insights_id" {
  description = "Application Insights resource ID for diagnostics."
  type        = string
  default     = null
}

variable "create_application_insights" {
  description = "Create Application Insights when application_insights_id is null."
  type        = bool
  default     = true
}

variable "application_insights_name" {
  description = "Application Insights name when created by the module."
  type        = string
  default     = null
}

variable "https_only" {
  description = "Require HTTPS."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the function app."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to function app resources."
  type        = map(string)
  default     = {}
}
