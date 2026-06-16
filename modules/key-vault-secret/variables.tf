variable "resource_group_name" {
  description = "Resource group name used to look up the Key Vault when vault_key.resource_group_name is not set."
  type        = string
}

variable "location" {
  description = "Azure region for the parent resource group. Not used by the secret resource itself."
  type        = string
}

variable "name" {
  description = "Name of the Key Vault secret."
  type        = string
}

variable "key_vault_id" {
  description = "Full resource ID of an existing Key Vault. Mutually exclusive with vault_key."
  type        = string
  default     = null
}

variable "vault_key" {
  description = "Reference to an existing Key Vault by name. Use key_vault_name from the key-vault module output."
  type = object({
    name                = string
    resource_group_name = optional(string)
  })
  default = null
}

variable "secret_value" {
  description = "Secret value as a UTF-8 string. Mutually exclusive with generate_random_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "generate_random_password" {
  description = "Generate a random password and store it as the secret value. Mutually exclusive with secret_value."
  type = object({
    length           = optional(number, 32)
    special          = optional(bool, true)
    override_special = optional(string, "!#$%&*()-_=+[]{}<>:?")
    username         = optional(string, null)
  })
  default = null
}

variable "ignore_secret_changes" {
  description = "Ignore changes to secret values after initial creation. Useful when values are rotated outside Terraform."
  type        = bool
  default     = false
}

variable "content_type" {
  description = "Content type of the secret."
  type        = string
  default     = null
}

variable "expiration_date" {
  description = "Expiration date in RFC3339 format."
  type        = string
  default     = null
}

variable "not_before_date" {
  description = "Not-before date in RFC3339 format."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the secret."
  type        = map(string)
  default     = {}
}
