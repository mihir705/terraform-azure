variable "resource_group_name" {
  description = "Resource group name when creating a Service Bus namespace."
  type        = string
}

variable "location" {
  description = "Azure region when creating a Service Bus namespace."
  type        = string
}

variable "create_namespace" {
  description = "Create a Service Bus namespace. Set to false to use an existing namespace."
  type        = bool
  default     = true
}

variable "namespace_name" {
  description = "Service Bus namespace name. Required when create_namespace is true."
  type        = string
  default     = null
}

variable "existing_namespace_name" {
  description = "Existing Service Bus namespace name. Required when create_namespace is false."
  type        = string
  default     = null
}

variable "existing_namespace_resource_group_name" {
  description = "Resource group of the existing namespace. Defaults to resource_group_name."
  type        = string
  default     = null
}

variable "namespace_sku" {
  description = "Service Bus namespace SKU: Basic, Standard, or Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.namespace_sku)
    error_message = "namespace_sku must be Basic, Standard, or Premium."
  }
}

variable "namespace_capacity" {
  description = "Messaging units for Premium SKU namespaces."
  type        = number
  default     = 1
}

variable "name" {
  description = "Queue name. Required unless name_prefix is set."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || (length(var.name) >= 1 && length(var.name) <= 260)
    error_message = "name must be between 1 and 260 characters."
  }
}

variable "name_prefix" {
  description = "Creates a unique queue name with the given prefix. Cannot be combined with name."
  type        = string
  default     = null
}

variable "enable_partitioning" {
  description = "Enable partitioning for the queue (Standard/Premium)."
  type        = bool
  default     = false
}

variable "enable_express" {
  description = "Enable express entities for the queue."
  type        = bool
  default     = false
}

variable "max_size_in_megabytes" {
  description = "Maximum queue size in megabytes."
  type        = number
  default     = 1024
}

variable "default_message_ttl" {
  description = "Default message TTL (ISO 8601 duration)."
  type        = string
  default     = null
}

variable "lock_duration" {
  description = "Lock duration (ISO 8601 duration, e.g. PT1M)."
  type        = string
  default     = null
}

variable "max_delivery_count" {
  description = "Max delivery count before dead-lettering."
  type        = number
  default     = 10
}

variable "requires_session" {
  description = "Require sessions for the queue."
  type        = bool
  default     = false
}

variable "requires_duplicate_detection" {
  description = "Enable duplicate detection on the queue."
  type        = bool
  default     = false
}

variable "duplicate_detection_history_time_window" {
  description = "Duplicate detection history window (ISO 8601 duration)."
  type        = string
  default     = null
}

variable "dead_lettering_on_message_expiration" {
  description = "Move expired messages to the dead-letter sub-queue."
  type        = bool
  default     = false
}

variable "create_dlq" {
  description = "Configure dead-letter behavior on the queue (Service Bus native DLQ sub-queue)."
  type        = bool
  default     = true
}

variable "forward_to" {
  description = "Forward messages to another queue or topic in the same namespace."
  type        = string
  default     = null
}

variable "forward_dead_lettered_messages_to" {
  description = "Forward dead-lettered messages to another entity."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
