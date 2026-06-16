variable "name" {
  description = "AKS cluster name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 63
    error_message = "name must be between 1 and 63 characters."
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

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane."
  type        = string
  default     = null
}

variable "dns_prefix" {
  description = "DNS prefix for the Kubernetes API server."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the default node pool and cluster networking."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet_id is required."
  }
}

variable "network_plugin" {
  description = "Network plugin: azure or kubenet."
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "network_plugin must be azure or kubenet."
  }
}

variable "network_policy" {
  description = "Network policy provider: azure or calico."
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "Kubernetes service CIDR."
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "Kubernetes DNS service IP address."
  type        = string
  default     = "10.0.0.10"
}

variable "pod_cidr" {
  description = "Pod CIDR when using kubenet."
  type        = string
  default     = "10.244.0.0/16"
}

variable "outbound_type" {
  description = "Outbound routing type: loadBalancer, userDefinedRouting, or managedNATGateway."
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway"], var.outbound_type)
    error_message = "outbound_type must be loadBalancer, userDefinedRouting, or managedNATGateway."
  }
}

variable "private_cluster_enabled" {
  description = "Enable a private API server endpoint."
  type        = bool
  default     = false
}

variable "local_account_disabled" {
  description = "Disable local accounts and enforce Azure AD RBAC only."
  type        = bool
  default     = false
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization."
  type        = bool
  default     = true
}

variable "role_based_access_control_enabled" {
  description = "Enable Kubernetes RBAC."
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs granted cluster admin when Azure RBAC is enabled."
  type        = list(string)
  default     = []
}

variable "identity" {
  description = "Cluster managed identity configuration."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = {
    type = "SystemAssigned"
  }
}

variable "default_node_pool" {
  description = "Default node pool configuration."
  type = object({
    name                         = optional(string, "system")
    vm_size                      = string
    node_count                   = optional(number)
    min_count                    = optional(number)
    max_count                    = optional(number)
    enable_auto_scaling          = optional(bool, false)
    os_disk_size_gb              = optional(number, 128)
    os_disk_type                 = optional(string, "Managed")
    os_sku                       = optional(string, "Ubuntu")
    zones                        = optional(list(string), [])
    max_pods                     = optional(number)
    node_labels                  = optional(map(string), {})
    node_taints                  = optional(list(string), [])
    subnet_id                    = optional(string)
    only_critical_addons_enabled = optional(bool, false)
  })
}

variable "additional_node_pools" {
  description = "Additional node pools keyed by logical name."
  type = map(object({
    vm_size             = string
    node_count          = optional(number)
    min_count           = optional(number)
    max_count           = optional(number)
    enable_auto_scaling = optional(bool, false)
    os_disk_size_gb     = optional(number, 128)
    os_disk_type        = optional(string, "Managed")
    os_sku              = optional(string, "Ubuntu")
    zones               = optional(list(string), [])
    max_pods            = optional(number)
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    subnet_id           = optional(string)
    mode                = optional(string, "User")
    priority            = optional(string, "Regular")
    spot_max_price      = optional(number)
    eviction_policy     = optional(string, "Delete")
  }))
  default = {}
}

variable "oms_agent" {
  description = "Log Analytics OMS agent configuration."
  type = object({
    log_analytics_workspace_id = string
  })
  default = null
}

variable "microsoft_defender_enabled" {
  description = "Enable Microsoft Defender for Containers."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to AKS resources."
  type        = map(string)
  default     = {}
}
