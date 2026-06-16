variable "resource_group_name" {
  description = "Name of the resource group containing the Key Vault."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
}

variable "name" {
  description = "Name of the Key Vault (3-24 alphanumeric characters and hyphens)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "name must be 3-24 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "tenant_id" {
  description = "Azure AD tenant ID. Defaults to the current client configuration."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU for the Key Vault."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain deleted vaults and objects."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  description = "Prevent permanent deletion during the retention period."
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Use Azure RBAC for authorization instead of vault access policies."
  type        = bool
  default     = true
}

variable "enabled_for_disk_encryption" {
  description = "Allow the vault to be used for disk encryption."
  type        = bool
  default     = false
}

variable "enabled_for_deployment" {
  description = "Allow virtual machines to retrieve certificates stored in the vault."
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Allow Azure Resource Manager to retrieve secrets from the vault."
  type        = bool
  default     = false
}

variable "access_policies" {
  description = "Vault access policies. Only used when enable_rbac_authorization is false."
  type = list(object({
    tenant_id               = optional(string)
    object_id               = string
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = []
}

variable "network_acls" {
  description = "Network ACLs for the Key Vault. Set to null to allow all networks."
  type = object({
    bypass                     = optional(string, "AzureServices")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = []
  }
}

variable "tags" {
  description = "Tags applied to the Key Vault."
  type        = map(string)
  default     = {}
}
