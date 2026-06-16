variable "azure_location" {
  description = "Primary Azure region where resources are created."
  type        = string
  default     = "eastus"
}

variable "azure_replica_location" {
  description = "Secondary Azure region for geo-redundant resources."
  type        = string
  default     = "westus"
}

variable "default_tags" {
  description = "Default tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "resource_groups" {
  description = "Resource groups to create. Omit when not managing resource groups."
  type = map(object({
    resource_group_name = string
    location            = optional(string)
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "storage_accounts" {
  description = "Storage accounts to create. Omit when not managing storage."
  type = map(object({
    resource_group_name      = optional(string)
    resource_group_key       = optional(string)
    location                 = optional(string)
    storage_account_name     = string
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    versioning_enabled       = optional(bool, false)
    containers = optional(map(object({
      access_type = optional(string, "private")
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "key_vaults" {
  description = "Key Vaults to create. Omit when not managing Key Vault."
  type = map(object({
    resource_group_name      = optional(string)
    resource_group_key       = optional(string)
    location                 = optional(string)
    name                     = string
    sku_name                 = optional(string, "standard")
    purge_protection_enabled = optional(bool, true)
    tags                     = optional(map(string), {})
  }))
  default = {}
}

variable "key_vault_secrets" {
  description = "Key Vault secrets to create. Omit when not managing secrets."
  type = map(object({
    resource_group_name = optional(string)
    resource_group_key  = optional(string)
    location            = optional(string)
    name                = string
    vault_key           = optional(string)
    key_vault_id        = optional(string)
    secret_value        = optional(string)
    generate_random_password = optional(object({
      length  = optional(number, 32)
      special = optional(bool, true)
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "key_vault_keys" {
  description = "Key Vault keys to create. Omit when not managing keys."
  type = map(object({
    resource_group_name = optional(string)
    resource_group_key  = optional(string)
    location            = optional(string)
    name                = string
    vault_key           = optional(string)
    key_vault_id        = optional(string)
    key_type            = optional(string, "RSA")
    key_size            = optional(number, 2048)
    key_opts            = optional(list(string), ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"])
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "vnets" {
  description = "Virtual networks to create. Omit when not managing VNet."
  type = map(object({
    name                = string
    resource_group_name = optional(string)
    resource_group_key  = optional(string)
    location            = optional(string)
    address_space       = list(string)
    public_subnets = map(object({
      availability_zone = string
      address_prefix    = string
    }))
    private_subnets = map(object({
      availability_zone = string
      address_prefix    = string
    }))
    enable_nat_gateway     = optional(bool, true)
    single_nat_gateway     = optional(bool, true)
    one_nat_gateway_per_az = optional(bool, false)
    tags                   = optional(map(string), {})
  }))
  default = {}
}

variable "network_security_groups" {
  description = "Network security groups to create. Omit when not managing NSG."
  type        = map(any)
  default     = {}
}

variable "load_balancers" {
  description = "Azure Load Balancers (L4) to create."
  type        = map(any)
  default     = {}
}

variable "application_gateways" {
  description = "Application Gateways (L7) to create."
  type        = map(any)
  default     = {}
}

variable "function_apps" {
  description = "Function apps to create."
  type        = map(any)
  default     = {}
}

variable "cdn_profiles" {
  description = "CDN profiles/endpoints to create."
  type        = map(any)
  default     = {}
}

variable "container_registries" {
  description = "Container registries to create."
  type        = map(any)
  default     = {}
}

variable "rbac_roles" {
  description = "RBAC identities and role assignments."
  type        = map(any)
  default     = {}
}

variable "virtual_machines" {
  description = "Virtual machines to create."
  type        = map(any)
  default     = {}
}

variable "postgresql_servers" {
  description = "PostgreSQL Flexible servers to create."
  type        = map(any)
  default     = {}
}

variable "api_management_services" {
  description = "API Management services to create."
  type        = map(any)
  default     = {}
}

variable "service_bus_topics" {
  description = "Service Bus topics to create."
  type        = map(any)
  default     = {}
}

variable "service_bus_queues" {
  description = "Service Bus queues to create."
  type        = map(any)
  default     = {}
}

variable "storage_queues" {
  description = "Storage queues to create."
  type        = map(any)
  default     = {}
}

variable "aks_clusters" {
  description = "AKS clusters to create."
  type        = map(any)
  default     = {}
}

variable "container_apps" {
  description = "Container Apps environments and apps."
  type        = map(any)
  default     = {}
}

variable "storage_shares" {
  description = "Azure Files shares to create."
  type        = map(any)
  default     = {}
}

variable "aadb2c_directories" {
  description = "Azure AD B2C directories to create."
  type        = map(any)
  default     = {}
}

variable "event_hubs_namespaces" {
  description = "Event Hubs namespaces to create."
  type        = map(any)
  default     = {}
}
