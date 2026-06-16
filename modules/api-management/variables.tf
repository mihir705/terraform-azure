variable "resource_group_name" {
  description = "Resource group name for the API Management service."
  type        = string
}

variable "location" {
  description = "Azure region for the API Management service."
  type        = string
}

variable "name" {
  description = "API Management service name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 50
    error_message = "name must be between 1 and 50 characters."
  }
}

variable "publisher_name" {
  description = "Publisher name shown in the developer portal."
  type        = string
}

variable "publisher_email" {
  description = "Publisher email for notifications."
  type        = string
}

variable "sku_name" {
  description = "API Management SKU: Developer_1, Basic_1, BasicV2_1, Standard_1, StandardV2_1, Premium_1, or Consumption_0."
  type        = string
  default     = "Developer_1"

  validation {
    condition = contains([
      "Developer_1",
      "Basic_1",
      "BasicV2_1",
      "Standard_1",
      "StandardV2_1",
      "Premium_1",
      "Consumption_0",
    ], var.sku_name)
    error_message = "sku_name is not a supported API Management SKU."
  }
}

variable "virtual_network_type" {
  description = "Virtual network integration type: None, External, or Internal."
  type        = string
  default     = "None"

  validation {
    condition     = contains(["None", "External", "Internal"], var.virtual_network_type)
    error_message = "virtual_network_type must be None, External, or Internal."
  }
}

variable "subnet_id" {
  description = "Subnet ID for External or Internal virtual network integration."
  type        = string
  default     = null
}

variable "identity_type" {
  description = "Managed identity type: SystemAssigned, UserAssigned, or null to disable."
  type        = string
  default     = null
}

variable "user_assigned_identity_ids" {
  description = "User-assigned identity IDs when identity_type includes UserAssigned."
  type        = list(string)
  default     = []
}

variable "apis" {
  description = "APIs keyed by logical name."
  type = map(object({
    name                  = optional(string)
    display_name          = string
    path                  = string
    protocols             = optional(list(string), ["https"])
    revision              = optional(string, "1")
    revision_description  = optional(string)
    service_url           = optional(string)
    subscription_required = optional(bool, true)
    import = optional(object({
      content_format = string
      content_value  = string
    }))
  }))
  default = {}
}

variable "operations" {
  description = "API operations keyed by logical name."
  type = map(object({
    api_key      = string
    operation_id = string
    display_name = string
    method       = string
    url_template = string
    description  = optional(string)
    template_parameter = optional(map(object({
      type        = string
      required    = optional(bool, false)
      description = optional(string)
    })), {})
  }))
  default = {}
}

variable "products" {
  description = "API Management products keyed by logical name."
  type = map(object({
    product_id            = optional(string)
    display_name          = string
    description           = optional(string)
    subscription_required = optional(bool, true)
    approval_required     = optional(bool, false)
    published             = optional(bool, true)
    api_keys              = optional(list(string), [])
  }))
  default = {}
}

variable "backends" {
  description = "Backends keyed by logical name."
  type = map(object({
    protocol    = string
    url         = string
    description = optional(string)
    tls = optional(object({
      validate_certificate_chain = optional(bool, true)
      validate_certificate_name  = optional(bool, true)
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to the API Management service."
  type        = map(string)
  default     = {}
}
