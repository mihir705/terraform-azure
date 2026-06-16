variable "resource_group_name" {
  description = "Resource group name when creating a user-assigned managed identity."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region when creating a user-assigned managed identity."
  type        = string
  default     = null
}

variable "name" {
  description = "Logical name for the identity or principal configuration."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 128
    error_message = "name must be between 1 and 128 characters."
  }
}

variable "identity_type" {
  description = "Principal type: user_assigned, service_principal, or existing_principal."
  type        = string
  default     = "user_assigned"

  validation {
    condition     = contains(["user_assigned", "service_principal", "existing_principal"], var.identity_type)
    error_message = "identity_type must be user_assigned, service_principal, or existing_principal."
  }
}

variable "create_user_assigned_identity" {
  description = "Create a user-assigned managed identity when identity_type is user_assigned."
  type        = bool
  default     = true
}

variable "user_assigned_identity_name" {
  description = "User-assigned identity resource name. Defaults to var.name."
  type        = string
  default     = null
}

variable "existing_principal_id" {
  description = "Existing principal object ID when identity_type is existing_principal."
  type        = string
  default     = null
}

variable "create_service_principal" {
  description = "Create an Azure AD application and service principal when identity_type is service_principal."
  type        = bool
  default     = true
}

variable "application_display_name" {
  description = "Display name for the Azure AD application when creating a service principal."
  type        = string
  default     = null
}

variable "sign_in_audience" {
  description = "Azure AD application sign-in audience."
  type        = string
  default     = "AzureADMyOrg"
}

variable "custom_role_definitions" {
  description = "Custom role definitions keyed by logical name (mirrors iam-policy)."
  type = map(object({
    role_name         = optional(string)
    description       = optional(string)
    scope             = string
    assignable_scopes = optional(list(string))
    permissions = object({
      actions          = optional(list(string), [])
      not_actions      = optional(list(string), [])
      data_actions     = optional(list(string), [])
      not_data_actions = optional(list(string), [])
    })
  }))
  default = {}
}

variable "role_assignments" {
  description = "Role assignments keyed by logical name."
  type = map(object({
    scope                      = string
    role_definition_id         = optional(string)
    role_definition_name       = optional(string)
    custom_role_definition_key = optional(string)
    description                = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to created Azure resources."
  type        = map(string)
  default     = {}
}
