variable "name" {
  description = "Azure Container Registry name."
  type        = string

  validation {
    condition     = length(var.name) >= 5 && length(var.name) <= 50 && can(regex("^[a-z0-9]+$", var.name))
    error_message = "name must be 5-50 lowercase alphanumeric characters."
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

variable "sku" {
  description = "ACR SKU: Basic, Standard, or Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user account."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the registry."
  type        = bool
  default     = true
}

variable "network_rule_set" {
  description = "Network rules for the registry. Requires Premium SKU."
  type = object({
    default_action = optional(string, "Deny")
    ip_rules = optional(list(object({
      action   = optional(string, "Allow")
      ip_range = string
    })), [])
  })
  default = null
}

variable "georeplications" {
  description = "Geo-replication locations. Requires Premium SKU."
  type = list(object({
    location                = string
    zone_redundancy_enabled = optional(bool, false)
    tags                    = optional(map(string), {})
  }))
  default = []
}

variable "retention_policy_in_days" {
  description = "Retention period in days for untagged manifests. Requires Premium SKU."
  type        = number
  default     = null
}

variable "trust_policy_enabled" {
  description = "Enable content trust policy. Requires Premium SKU."
  type        = bool
  default     = false
}

variable "export_policy_enabled" {
  description = "Allow artifact export. Requires Premium SKU."
  type        = bool
  default     = true
}

variable "identity" {
  description = "Managed identity configuration."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}

variable "tags" {
  description = "Tags applied to the container registry."
  type        = map(string)
  default     = {}
}
