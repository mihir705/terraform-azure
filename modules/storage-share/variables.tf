variable "resource_group_name" {
  description = "Resource group name when creating a storage account."
  type        = string
}

variable "location" {
  description = "Azure region when creating a storage account."
  type        = string
}

variable "create_storage_account" {
  description = "Create a storage account for the file share. Set to false to use an existing account."
  type        = bool
  default     = true
}

variable "storage_account_name" {
  description = "Storage account name. Required when create_storage_account is true."
  type        = string
  default     = null
}

variable "existing_storage_account_name" {
  description = "Existing storage account name. Required when create_storage_account is false."
  type        = string
  default     = null
}

variable "existing_storage_account_resource_group_name" {
  description = "Resource group of the existing storage account. Defaults to resource_group_name."
  type        = string
  default     = null
}

variable "storage_account_tier" {
  description = "Storage account tier when created by this module."
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage replication type when the account is created by this module."
  type        = string
  default     = "LRS"
}

variable "enable_large_file_share" {
  description = "Enable large file share support on the storage account when created."
  type        = bool
  default     = true
}

variable "name" {
  description = "Azure Files share name."
  type        = string

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 63
    error_message = "name must be between 3 and 63 characters."
  }
}

variable "quota_gb" {
  description = "Share quota in gigabytes."
  type        = number
  default     = 100

  validation {
    condition     = var.quota_gb >= 1 && var.quota_gb <= 102400
    error_message = "quota_gb must be between 1 and 102400."
  }
}

variable "access_tier" {
  description = "Share access tier: TransactionOptimized, Hot, Cool, or Premium (Premium accounts only)."
  type        = string
  default     = "TransactionOptimized"

  validation {
    condition     = var.access_tier == null || contains(["TransactionOptimized", "Hot", "Cool", "Premium"], var.access_tier)
    error_message = "access_tier must be TransactionOptimized, Hot, Cool, or Premium."
  }
}

variable "enabled_protocol" {
  description = "File share protocol: SMB or NFS."
  type        = string
  default     = "SMB"

  validation {
    condition     = contains(["SMB", "NFS"], var.enabled_protocol)
    error_message = "enabled_protocol must be SMB or NFS."
  }
}

variable "metadata" {
  description = "Share metadata key/value pairs."
  type        = map(string)
  default     = {}
}

variable "acl" {
  description = "Optional share ACL entries."
  type = list(object({
    id = string
    access_policy = optional(object({
      permissions = string
      start       = optional(string)
      expiry      = optional(string)
    }))
  }))
  default = []
}

variable "directories" {
  description = "Subdirectories to create in the share, keyed by directory path name."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
