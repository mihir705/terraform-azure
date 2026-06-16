variable "name" {
  description = "Name of the Application Gateway and related resources."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 80
    error_message = "name must be between 1 and 80 characters."
  }
}

variable "resource_group_name" {
  description = "Resource group where Application Gateway resources are created."
  type        = string
}

variable "location" {
  description = "Azure region for Application Gateway resources."
  type        = string
}

variable "vnet_id" {
  description = "Virtual network ID for Application Gateway integration."
  type        = string
}

variable "subnet_id" {
  description = "Dedicated subnet ID for the Application Gateway (must be named GatewaySubnet or dedicated AGW subnet)."
  type        = string
}

variable "internal" {
  description = "Create an internal Application Gateway. Set to false for an internet-facing gateway."
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable Web Application Firewall (WAF_v2 SKU)."
  type        = bool
  default     = false
}

variable "waf_mode" {
  description = "WAF operating mode when enable_waf is true."
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "waf_mode must be Detection or Prevention."
  }
}

variable "capacity" {
  description = "Number of Application Gateway capacity units (instances)."
  type        = number
  default     = 2

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 125
    error_message = "capacity must be between 1 and 125."
  }
}

variable "public_ip_address_id" {
  description = "Existing public IP address ID. Created automatically when null and internal is false."
  type        = string
  default     = null
}

variable "public_ip_zones" {
  description = "Availability zones for the auto-created public IP."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "enable_http2" {
  description = "Enable HTTP/2 on the Application Gateway."
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the Application Gateway."
  type        = bool
  default     = false
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the gateway on HTTP and HTTPS (via optional NSG at subnet level)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "target_groups" {
  description = "Backend pools and HTTP settings keyed by logical name."
  type = map(object({
    port                                      = number
    protocol                                  = string
    cookie_based_affinity                     = optional(string, "Disabled")
    connection_draining_enabled               = optional(bool, false)
    connection_draining_timeout_sec           = optional(number, 30)
    health_check_enabled                      = optional(bool, true)
    health_check_interval                     = optional(number, 30)
    health_check_path                         = optional(string, "/")
    health_check_port                         = optional(number)
    health_check_protocol                     = optional(string, "Http")
    health_check_timeout                      = optional(number, 30)
    health_check_unhealthy_threshold          = optional(number, 3)
    health_check_matcher                      = optional(string, "200-399")
    pick_host_name_from_backend_http_settings = optional(bool, false)
    host_name                                 = optional(string)
    targets = optional(list(object({
      ip_address = optional(string)
      fqdn       = optional(string)
    })), [])
  }))
}

variable "listeners" {
  description = "HTTP listeners and routing rules keyed by logical name."
  type = map(object({
    port                = number
    protocol            = string
    certificate_name    = optional(string)
    key_vault_secret_id = optional(string)
    ssl_policy_name     = optional(string)
    default_action = object({
      type             = string
      target_group_key = optional(string)
      redirect = optional(object({
        redirect_type        = string
        target_url           = optional(string)
        include_path         = optional(bool, true)
        include_query_string = optional(bool, true)
      }))
      fixed_response = optional(object({
        content_type = string
        message_body = string
        status_code  = string
      }))
    })
    rules = optional(list(object({
      name         = string
      priority     = number
      path_pattern = optional(list(string))
      host_names   = optional(list(string))
      action = object({
        type             = string
        target_group_key = optional(string)
        redirect = optional(object({
          redirect_type        = string
          target_url           = optional(string)
          include_path         = optional(bool, true)
          include_query_string = optional(bool, true)
        }))
        fixed_response = optional(object({
          content_type = string
          message_body = string
          status_code  = string
        }))
      })
    })), [])
  }))
}

variable "tags" {
  description = "Tags applied to Application Gateway resources."
  type        = map(string)
  default     = {}
}
