variable "name" {
  description = "Name prefix applied to VNet resources and Name tags."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where VNet resources are created."
  type        = string
}

variable "location" {
  description = "Azure region for VNet resources."
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnets keyed by logical name. Typically two subnets across two zones."
  type = map(object({
    availability_zone = string
    address_prefix    = string
  }))
}

variable "private_subnets" {
  description = "Private subnets keyed by logical name. Typically two subnets across two zones."
  type = map(object({
    availability_zone = string
    address_prefix    = string
  }))
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) for private subnet egress."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway in the first public subnet. Lower cost, single zone egress dependency."
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Create one NAT gateway per availability zone used by public subnets. Higher availability."
  type        = bool
  default     = false
}

variable "create_public_nacl" {
  description = "Create a dedicated subnet Network Security Group for public subnets (Azure equivalent of a public NACL)."
  type        = bool
  default     = true
}

variable "create_private_nacl" {
  description = "Create a dedicated subnet Network Security Group for private subnets (Azure equivalent of a private NACL)."
  type        = bool
  default     = true
}

variable "public_nacl_ingress_rules" {
  description = "Ingress rules for the public subnet NSG."
  type = list(object({
    priority                   = number
    name                       = optional(string)
    protocol                   = string
    access                     = string
    source_address_prefix      = string
    destination_address_prefix = optional(string, "*")
    destination_port_range     = optional(string)
    source_port_range          = optional(string, "*")
  }))
  default = [
    {
      priority               = 100
      name                   = "allow-http"
      protocol               = "Tcp"
      access                 = "Allow"
      source_address_prefix  = "*"
      destination_port_range = "80"
    },
    {
      priority               = 110
      name                   = "allow-https"
      protocol               = "Tcp"
      access                 = "Allow"
      source_address_prefix  = "*"
      destination_port_range = "443"
    },
    {
      priority               = 120
      name                   = "allow-ephemeral-tcp"
      protocol               = "Tcp"
      access                 = "Allow"
      source_address_prefix  = "*"
      destination_port_range = "1024-65535"
    },
    {
      priority               = 130
      name                   = "allow-ephemeral-udp"
      protocol               = "Udp"
      access                 = "Allow"
      source_address_prefix  = "*"
      destination_port_range = "1024-65535"
    },
  ]
}

variable "public_nacl_egress_rules" {
  description = "Egress rules for the public subnet NSG."
  type = list(object({
    priority                   = number
    name                       = optional(string)
    protocol                   = string
    access                     = string
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = string
    destination_port_range     = optional(string, "*")
    source_port_range          = optional(string, "*")
  }))
  default = [
    {
      priority                   = 100
      name                       = "allow-all-outbound"
      protocol                   = "*"
      access                     = "Allow"
      destination_address_prefix = "*"
    },
  ]
}

variable "private_nacl_ingress_rules" {
  description = "Ingress rules for the private subnet NSG. Defaults to allow all traffic from the VNet address space."
  type = list(object({
    priority                   = number
    name                       = optional(string)
    protocol                   = string
    access                     = string
    source_address_prefix      = string
    destination_address_prefix = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_port_range          = optional(string, "*")
  }))
  default = null
}

variable "private_nacl_egress_rules" {
  description = "Egress rules for the private subnet NSG."
  type = list(object({
    priority                   = number
    name                       = optional(string)
    protocol                   = string
    access                     = string
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = string
    destination_port_range     = optional(string, "*")
    source_port_range          = optional(string, "*")
  }))
  default = [
    {
      priority                   = 100
      name                       = "allow-all-outbound"
      protocol                   = "*"
      access                     = "Allow"
      destination_address_prefix = "*"
    },
  ]
}

variable "tags" {
  description = "Tags applied to all VNet resources."
  type        = map(string)
  default     = {}
}
