variable "name" {
  description = "PostgreSQL Flexible Server name."
  type        = string

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 63
    error_message = "name must be between 3 and 63 characters."
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

variable "sku_name" {
  description = "SKU name (e.g. B_Standard_B1ms, GP_Standard_D2s_v3)."
  type        = string
}

variable "postgres_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"

  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16"], var.postgres_version)
    error_message = "postgres_version must be 11 through 16."
  }
}

variable "administrator_login" {
  description = "Administrator login name."
  type        = string
}

variable "administrator_password" {
  description = "Administrator password. Omit when using generate_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "generate_password" {
  description = "Generate a random administrator password in Terraform."
  type = object({
    length           = optional(number, 32)
    special          = optional(bool, true)
    override_special = optional(string, "!#$%&*()-_=+[]{}<>:?")
  })
  default = {
    length = 32
  }
}

variable "storage_mb" {
  description = "Storage size in MB."
  type        = number
  default     = 32768

  validation {
    condition     = var.storage_mb >= 32768 && var.storage_mb <= 16777216
    error_message = "storage_mb must be between 32768 and 16777216."
  }
}

variable "storage_tier" {
  description = "Storage tier: P1 through P80 or Burstable tier equivalents."
  type        = string
  default     = null
}

variable "auto_grow_enabled" {
  description = "Enable storage auto-grow."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention in days."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup."
  type        = bool
  default     = false
}

variable "high_availability" {
  description = "High availability configuration."
  type = object({
    mode                      = string
    standby_availability_zone = optional(string)
  })
  default = null

  validation {
    condition = (
      var.high_availability == null ||
      contains(["SameZone", "ZoneRedundant"], var.high_availability.mode)
    )
    error_message = "high_availability.mode must be SameZone or ZoneRedundant."
  }
}

variable "maintenance_window" {
  description = "Maintenance window configuration."
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = optional(number, 0)
  })
  default = null
}

variable "delegated_subnet_id" {
  description = "Delegated subnet ID for VNet integration. Required when public_network_access_enabled is false unless using private endpoint only."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for the server FQDN. Created automatically when create_private_dns_zone is true."
  type        = string
  default     = null
}

variable "create_private_dns_zone" {
  description = "Create a private DNS zone for PostgreSQL when private_dns_zone_id is null."
  type        = bool
  default     = false
}

variable "private_dns_zone_name" {
  description = "Private DNS zone name when created by the module."
  type        = string
  default     = "privatelink.postgres.database.azure.com"
}

variable "public_network_access_enabled" {
  description = "Allow public network access."
  type        = bool
  default     = false
}

variable "databases" {
  description = "Databases to create on the server keyed by logical name."
  type = map(object({
    charset   = optional(string, "UTF8")
    collation = optional(string, "en_US.utf8")
  }))
  default = {}
}

variable "configurations" {
  description = "Server configuration parameters."
  type = map(object({
    value = string
  }))
  default = {}
}

variable "zone" {
  description = "Availability zone for the server."
  type        = string
  default     = null
}

variable "virtual_network_id" {
  description = "Virtual network ID for private DNS zone linking when create_private_dns_zone is true."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to PostgreSQL resources."
  type        = map(string)
  default     = {}
}
