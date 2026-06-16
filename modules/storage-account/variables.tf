variable "resource_group_name" {
  description = "Name of the resource group containing the storage account."
  type        = string
}

variable "location" {
  description = "Azure region for the storage account."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique storage account name (3-24 lowercase letters and numbers)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters and contain only lowercase letters and numbers."
  }
}

variable "account_tier" {
  description = "Storage account tier. Use Standard for general purpose or Premium for high-performance block blobs."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Replication type for the storage account."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "account_replication_type must be one of LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }
}

variable "account_kind" {
  description = "Kind of storage account."
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["StorageV2", "BlobStorage", "BlockBlobStorage", "FileStorage"], var.account_kind)
    error_message = "account_kind must be StorageV2, BlobStorage, BlockBlobStorage, or FileStorage."
  }
}

variable "access_tier" {
  description = "Default access tier for blob data."
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "access_tier must be Hot or Cool."
  }
}

variable "versioning_enabled" {
  description = "Enable blob versioning."
  type        = bool
  default     = false
}

variable "change_feed_enabled" {
  description = "Enable blob change feed."
  type        = bool
  default     = false
}

variable "blob_delete_retention_days" {
  description = "Soft-delete retention period for blobs in days."
  type        = number
  default     = 7

  validation {
    condition     = var.blob_delete_retention_days >= 1 && var.blob_delete_retention_days <= 365
    error_message = "blob_delete_retention_days must be between 1 and 365."
  }
}

variable "container_delete_retention_days" {
  description = "Soft-delete retention period for containers in days."
  type        = number
  default     = 7

  validation {
    condition     = var.container_delete_retention_days >= 1 && var.container_delete_retention_days <= 365
    error_message = "container_delete_retention_days must be between 1 and 365."
  }
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption with a secondary encryption layer."
  type        = bool
  default     = true
}

variable "https_traffic_only_enabled" {
  description = "Require HTTPS for all requests."
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version for HTTPS requests."
  type        = string
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "min_tls_version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Allow nested blob/container public access. Set to false to block anonymous public access."
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Allow shared key authorization. Disable when using Azure AD and managed identities only."
  type        = bool
  default     = true
}

variable "containers" {
  description = "Blob containers to create in the storage account."
  type = map(object({
    access_type = optional(string, "private")
    metadata    = optional(map(string))
  }))
  default = {}
}

variable "network_rules" {
  description = "Network rules for the storage account. Set to null to allow all networks."
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })), [])
  })
  default = null
}

variable "lifecycle_rules" {
  description = "Blob lifecycle management rules."
  type = list(object({
    name    = string
    enabled = optional(bool, true)
    filter = optional(object({
      prefix_match = optional(list(string))
      blob_types   = optional(list(string), ["blockBlob"])
      tags = optional(list(object({
        name  = string
        op    = string
        value = string
      })), [])
    }))
    actions = object({
      base_blob = optional(object({
        tier_to_cool_after_days    = optional(number)
        tier_to_archive_after_days = optional(number)
        delete_after_days          = optional(number)
      }))
      version = optional(object({
        delete_after_days = optional(number)
      }))
      snapshot = optional(object({
        delete_after_days = optional(number)
      }))
    })
  }))
  default = []
}

variable "customer_managed_key" {
  description = "Customer-managed key encryption configuration. Set to null to use Microsoft-managed keys."
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  default = null
}

variable "tags" {
  description = "Tags applied to the storage account."
  type        = map(string)
  default     = {}
}
