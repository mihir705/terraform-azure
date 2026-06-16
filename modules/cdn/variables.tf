variable "resource_group_name" {
  description = "Resource group name for CDN and optional origin storage account."
  type        = string
}

variable "location" {
  description = "Azure region for CDN profile and optional origin storage account."
  type        = string
}

variable "name" {
  description = "CDN profile name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 260
    error_message = "name must be between 1 and 260 characters."
  }
}

variable "sku_name" {
  description = "CDN profile SKU: Standard_Akamai, Standard_Microsoft, Standard_Verizon, or Premium_Verizon."
  type        = string
  default     = "Standard_Microsoft"

  validation {
    condition     = contains(["Standard_Akamai", "Standard_Microsoft", "Standard_Verizon", "Premium_Verizon"], var.sku_name)
    error_message = "sku_name must be Standard_Akamai, Standard_Microsoft, Standard_Verizon, or Premium_Verizon."
  }
}

variable "endpoint_name" {
  description = "CDN endpoint name within the profile."
  type        = string

  validation {
    condition     = length(var.endpoint_name) >= 1 && length(var.endpoint_name) <= 50
    error_message = "endpoint_name must be between 1 and 50 characters."
  }
}

variable "create_origin_storage_account" {
  description = "Create a dedicated storage account as the CDN origin. Set to false to use an existing storage account."
  type        = bool
  default     = true
}

variable "origin_storage_account_name" {
  description = "Storage account name for the origin. Required when create_origin_storage_account is true."
  type        = string
  default     = null
}

variable "origin_storage_account_tier" {
  description = "Storage account tier when created by this module."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.origin_storage_account_tier)
    error_message = "origin_storage_account_tier must be Standard or Premium."
  }
}

variable "origin_storage_replication_type" {
  description = "Storage replication type when the origin account is created by this module."
  type        = string
  default     = "LRS"
}

variable "existing_origin_storage_account_name" {
  description = "Existing origin storage account name. Required when create_origin_storage_account is false."
  type        = string
  default     = null
}

variable "existing_origin_storage_account_resource_group_name" {
  description = "Resource group of the existing origin storage account. Defaults to resource_group_name."
  type        = string
  default     = null
}

variable "origin_host_name" {
  description = "Origin host name. Defaults to the storage account primary blob host when using storage origin."
  type        = string
  default     = null
}

variable "origin_host_header" {
  description = "Host header sent to the origin. Defaults to origin_host_name."
  type        = string
  default     = null
}

variable "origin_path" {
  description = "Optional path prefix on the origin (e.g. /container)."
  type        = string
  default     = ""
}

variable "origin_sas_token" {
  description = "SAS token for private blob origins. Omit when the origin allows anonymous read."
  type        = string
  default     = null
  sensitive   = true
}

variable "is_http_allowed" {
  description = "Allow HTTP requests to the CDN endpoint."
  type        = bool
  default     = false
}

variable "is_https_allowed" {
  description = "Allow HTTPS requests to the CDN endpoint."
  type        = bool
  default     = true
}

variable "querystring_caching_behaviour" {
  description = "Query string caching behaviour: IgnoreQueryString, BypassCaching, or UseQueryString."
  type        = string
  default     = "IgnoreQueryString"

  validation {
    condition     = contains(["IgnoreQueryString", "BypassCaching", "UseQueryString"], var.querystring_caching_behaviour)
    error_message = "querystring_caching_behaviour must be IgnoreQueryString, BypassCaching, or UseQueryString."
  }
}

variable "optimization_type" {
  description = "CDN optimization type: GeneralWebDelivery, GeneralMediaStreaming, VideoOnDemandMediaStreaming, LargeFileDownload, or DynamicSiteAcceleration."
  type        = string
  default     = "GeneralWebDelivery"

  validation {
    condition = contains([
      "GeneralWebDelivery",
      "GeneralMediaStreaming",
      "VideoOnDemandMediaStreaming",
      "LargeFileDownload",
      "DynamicSiteAcceleration",
    ], var.optimization_type)
    error_message = "optimization_type is not a supported CDN optimization type."
  }
}

variable "geo_filter" {
  description = "Optional geo filter for the endpoint."
  type = object({
    relative_path = string
    action        = string
    country_codes = list(string)
  })
  default = null

  validation {
    condition     = var.geo_filter == null || contains(["Allow", "Block"], var.geo_filter.action)
    error_message = "geo_filter.action must be Allow or Block."
  }
}

variable "custom_domains" {
  description = "Custom domains attached to the CDN endpoint."
  type = map(object({
    host_name = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
