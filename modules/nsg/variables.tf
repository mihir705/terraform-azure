variable "name" {
  description = "Name of the Network Security Group."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 80
    error_message = "name must be between 1 and 80 characters."
  }
}

variable "resource_group_name" {
  description = "Resource group where the NSG is created."
  type        = string
}

variable "location" {
  description = "Azure region for the NSG."
  type        = string
}

variable "vnet_id" {
  description = "Virtual network ID where the NSG is scoped. Used for validation and documentation; NSGs are regional resources associated with subnets or NICs."
  type        = string
  default     = null
}

variable "description" {
  description = "NSG description."
  type        = string
  default     = null
}

variable "ingress_rules" {
  description = "Inbound security rules for the NSG."
  type = list(object({
    name                                       = optional(string)
    description                                = optional(string)
    priority                                   = optional(number)
    protocol                                   = string
    source_port_range                          = optional(string, "*")
    destination_port_range                     = optional(string)
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(list(string), [])
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string), [])
    source_application_security_group_ids      = optional(list(string), [])
    destination_application_security_group_ids = optional(list(string), [])
    referenced_network_security_group_id       = optional(string)
    self_reference                             = optional(bool, false)
  }))
  default = []
}

variable "egress_rules" {
  description = "Outbound security rules for the NSG. Defaults to allow all outbound IPv4 traffic."
  type = list(object({
    name                                       = optional(string)
    description                                = optional(string)
    priority                                   = optional(number)
    protocol                                   = string
    source_port_range                          = optional(string, "*")
    destination_port_range                     = optional(string)
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(list(string), [])
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string), [])
    source_application_security_group_ids      = optional(list(string), [])
    destination_application_security_group_ids = optional(list(string), [])
    referenced_network_security_group_id       = optional(string)
    self_reference                             = optional(bool, false)
  }))
  default = null
}

variable "tags" {
  description = "Tags applied to the NSG."
  type        = map(string)
  default     = {}
}
