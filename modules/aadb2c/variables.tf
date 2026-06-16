variable "resource_group_name" {
  description = "Resource group name for the Azure AD B2C directory."
  type        = string
}

variable "country_code" {
  description = "Country code for the B2C directory (ISO 3166-1 alpha-2)."
  type        = string

  validation {
    condition     = length(var.country_code) == 2
    error_message = "country_code must be a two-letter ISO 3166-1 alpha-2 code."
  }
}

variable "display_name" {
  description = "Display name for the B2C tenant."
  type        = string
}

variable "domain_name" {
  description = "Initial domain prefix for the B2C tenant (becomes <domain_name>.onmicrosoft.com)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.domain_name))
    error_message = "domain_name may only contain letters, numbers, and hyphens."
  }
}

variable "data_residency_location" {
  description = "Data residency location for the B2C directory (typically the country code)."
  type        = string
  default     = null
}

variable "data_localization_type" {
  description = "Data localization type: Localized (country-specific) or Geographic (regional)."
  type        = string
  default     = "Localized"

  validation {
    condition     = contains(["Localized", "Geographic"], var.data_localization_type)
    error_message = "data_localization_type must be Localized or Geographic."
  }
}

variable "sku_name" {
  description = "B2C tenant SKU: PremiumP1 or PremiumP2."
  type        = string
  default     = "PremiumP1"

  validation {
    condition     = contains(["PremiumP1", "PremiumP2"], var.sku_name)
    error_message = "sku_name must be PremiumP1 or PremiumP2."
  }
}

variable "tags" {
  description = "Tags applied to the B2C directory resource."
  type        = map(string)
  default     = {}
}
