variable "resource_group_name" {
  description = "Resource group name for the Event Hubs namespace."
  type        = string
}

variable "location" {
  description = "Azure region for the Event Hubs namespace."
  type        = string
}

variable "namespace_name" {
  description = "Event Hubs namespace name."
  type        = string

  validation {
    condition     = length(var.namespace_name) >= 1 && length(var.namespace_name) <= 260
    error_message = "namespace_name must be between 1 and 260 characters."
  }
}

variable "sku" {
  description = "Event Hubs namespace SKU: Basic, Standard, or Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  description = "Throughput units (Standard) or processing units (Premium)."
  type        = number
  default     = 1
}

variable "auto_inflate_enabled" {
  description = "Enable auto-inflate for Standard SKU namespaces."
  type        = bool
  default     = false
}

variable "maximum_throughput_units" {
  description = "Maximum throughput units when auto_inflate_enabled is true."
  type        = number
  default     = null
}

variable "zone_redundant" {
  description = "Enable zone redundancy for the namespace."
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "Minimum TLS version for the namespace."
  type        = string
  default     = "1.2"
}

variable "event_hub_name" {
  description = "Event hub name. Required unless event_hub_name_prefix is set."
  type        = string
  default     = null
}

variable "event_hub_name_prefix" {
  description = "Event hub name prefix. Cannot be combined with event_hub_name."
  type        = string
  default     = null
}

variable "partition_count" {
  description = "Number of partitions for the event hub."
  type        = number
  default     = 2

  validation {
    condition     = var.partition_count >= 1 && var.partition_count <= 32
    error_message = "partition_count must be between 1 and 32."
  }
}

variable "message_retention" {
  description = "Message retention in days for the event hub."
  type        = number
  default     = 1

  validation {
    condition     = var.message_retention >= 1 && var.message_retention <= 90
    error_message = "message_retention must be between 1 and 90."
  }
}

variable "capture_description" {
  description = "Optional capture configuration for the event hub."
  type = object({
    enabled             = bool
    encoding            = string
    interval_in_seconds = optional(number, 300)
    size_limit_in_bytes = optional(number, 314572800)
    destination = object({
      name                = string
      archive_name_format = string
      blob_container_name = string
      storage_account_id  = string
    })
  })
  default = null
}

variable "consumer_groups" {
  description = "Consumer groups keyed by logical name."
  type = map(object({
    name = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
