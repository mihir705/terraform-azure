variable "name" {
  description = "Container Apps Environment name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 60
    error_message = "name must be between 1 and 60 characters."
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

variable "infrastructure_subnet_id" {
  description = "Delegated subnet ID for the Container Apps Environment."
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Use an internal load balancer for environment ingress."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy for the environment."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for environment diagnostics."
  type        = string
  default     = null
}

variable "create_log_analytics_workspace" {
  description = "Create a Log Analytics workspace when log_analytics_workspace_id is null."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name when created by the module."
  type        = string
  default     = null
}

variable "dapr_application_insights_connection_string" {
  description = "Application Insights connection string for Dapr telemetry."
  type        = string
  default     = null
  sensitive   = true
}

variable "container_apps" {
  description = "Container apps keyed by logical name."
  type = map(object({
    revision_mode         = optional(string, "Single")
    workload_profile_name = optional(string)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    secrets = optional(list(object({
      name                = string
      value               = optional(string)
      key_vault_secret_id = optional(string)
      identity            = optional(string)
    })), [])
    ingress = optional(object({
      external_enabled           = optional(bool, true)
      target_port                = number
      transport                  = optional(string, "auto")
      allow_insecure_connections = optional(bool, false)
      traffic_weight = optional(list(object({
        label           = optional(string)
        latest_revision = optional(bool, true)
        revision_suffix = optional(string)
        percentage      = optional(number, 100)
      })), [])
    }))
    template = object({
      min_replicas = optional(number, 0)
      max_replicas = optional(number, 10)
      containers = map(object({
        name    = string
        image   = string
        cpu     = optional(number, 0.25)
        memory  = optional(string, "0.5Gi")
        args    = optional(list(string), [])
        command = optional(list(string), [])
        env = optional(list(object({
          name        = string
          value       = optional(string)
          secret_name = optional(string)
        })), [])
      }))
      scale_rules = optional(list(object({
        name = string
        custom = optional(object({
          type             = string
          metadata         = map(string)
          auth_secret_name = optional(string)
          identity_id      = optional(string)
        }))
        http = optional(object({
          concurrent_requests = optional(string)
        }))
        azure_queue = optional(object({
          queue_name       = string
          queue_length     = optional(number, 10)
          auth_secret_name = optional(string)
        }))
      })), [])
    })
  }))
}

variable "tags" {
  description = "Tags applied to Container Apps resources."
  type        = map(string)
  default     = {}
}
