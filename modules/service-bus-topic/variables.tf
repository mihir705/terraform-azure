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
  description = "Topic name. Required unless name_prefix is set."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || (length(var.name) >= 1 && length(var.name) <= 260)
    error_message = "name must be between 1 and 260 characters."
  }
}

variable "name_prefix" {
  description = "Creates a unique topic name with the given prefix. Cannot be combined with name."
  type        = string
  default     = null
}

variable "enable_partitioning" {
  description = "Enable partitioning for the topic (Standard/Premium)."
  type        = bool
  default     = false
}

variable "enable_express" {
  description = "Enable express entities for the topic."
  type        = bool
  default     = false
}

variable "max_size_in_megabytes" {
  description = "Maximum topic size in megabytes."
  type        = number
  default     = 1024
}

variable "default_message_ttl" {
  description = "Default message TTL (ISO 8601 duration, e.g. P14D)."
  type        = string
  default     = null
}

variable "duplicate_detection_history_time_window" {
  description = "Duplicate detection history window (ISO 8601 duration)."
  type        = string
  default     = null
}

variable "requires_duplicate_detection" {
  description = "Enable duplicate detection on the topic."
  type        = bool
  default     = false
}

variable "support_ordering" {
  description = "Support message ordering on the topic."
  type        = bool
  default     = false
}

variable "subscriptions" {
  description = "Topic subscriptions keyed by logical name."
  type = map(object({
    max_delivery_count                        = optional(number, 10)
    default_message_ttl                       = optional(string)
    lock_duration                             = optional(string)
    requires_session                          = optional(bool, false)
    dead_lettering_on_message_expiration      = optional(bool, false)
    dead_lettering_on_filter_evaluation_error = optional(bool, true)
    auto_delete_on_idle                       = optional(string)
    forward_to                                = optional(string)
    forward_dead_lettered_messages_to         = optional(string)
    sql_filter                                = optional(string)
    correlation_filter = optional(object({
      correlation_id      = optional(string)
      message_id          = optional(string)
      to                  = optional(string)
      reply_to            = optional(string)
      label               = optional(string)
      session_id          = optional(string)
      to_subscription     = optional(string)
      reply_to_session_id = optional(string)
      content_type        = optional(string)
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
