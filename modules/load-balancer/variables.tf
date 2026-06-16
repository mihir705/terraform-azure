variable "name" {
  description = "Name of the Azure Load Balancer and related resources."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 80
    error_message = "name must be between 1 and 80 characters."
  }
}

variable "resource_group_name" {
  description = "Resource group where load balancer resources are created."
  type        = string
}

variable "location" {
  description = "Azure region for load balancer resources."
  type        = string
}

variable "vnet_id" {
  description = "Virtual network ID for backend pool context."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for internal load balancer frontends. Required when internal is true unless frontend_subnet_id is set."
  type        = list(string)
  default     = []
}

variable "frontend_subnet_id" {
  description = "Subnet ID for the internal frontend IP configuration. Defaults to the first subnet_ids entry."
  type        = string
  default     = null
}

variable "internal" {
  description = "Create an internal load balancer. Set to false for a public load balancer."
  type        = bool
  default     = false
}

variable "sku" {
  description = "Load balancer SKU. Standard is required for zone redundancy and HA ports."
  type        = string
  default     = "Standard"

  validation {
    condition     = var.sku == "Standard"
    error_message = "sku must be Standard."
  }
}

variable "public_ip_address_id" {
  description = "Existing public IP address ID for internet-facing load balancers. Created automatically when null and internal is false."
  type        = string
  default     = null
}

variable "public_ip_zones" {
  description = "Availability zones for the auto-created public IP."
  type        = list(string)
  default     = ["1", "2", "3"]
}


variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing on load balancing rules."
  type        = bool
  default     = true
}

variable "target_groups" {
  description = "Backend address pools keyed by logical name."
  type = map(object({
    port                             = number
    protocol                         = string
    health_check_enabled             = optional(bool, true)
    health_check_protocol            = optional(string, "Tcp")
    health_check_port                = optional(number)
    health_check_interval_in_seconds = optional(number, 15)
    health_check_number_of_probes    = optional(number, 2)
    health_check_request_path        = optional(string)
    load_distribution                = optional(string, "Default")
    targets = optional(list(object({
      ip_address = string
      name       = optional(string)
    })), [])
  }))
}

variable "listeners" {
  description = "Load balancing rules keyed by logical name."
  type = map(object({
    port                    = number
    protocol                = string
    target_group_key        = string
    frontend_port           = optional(number)
    idle_timeout_in_minutes = optional(number, 4)
    enable_floating_ip      = optional(bool, false)
    disable_outbound_snat   = optional(bool, false)
  }))
}

variable "tags" {
  description = "Tags applied to load balancer resources."
  type        = map(string)
  default     = {}
}
