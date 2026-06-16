variable "resource_group_name" {
  description = "Resource group name used to look up the Key Vault when vault_key.resource_group_name is not set."
  type        = string
}

variable "location" {
  description = "Azure region for the parent resource group. Not used by the key resource itself."
  type        = string
}

variable "name" {
  description = "Name of the Key Vault key."
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

variable "key_type" {
  description = "Key type to create."
  type        = string
  default     = "RSA"

  validation {
    condition     = contains(["RSA", "RSA-HSM", "EC", "EC-HSM"], var.key_type)
    error_message = "key_type must be RSA, RSA-HSM, EC, or EC-HSM."
  }
}

variable "key_size" {
  description = "Key size in bits. Required for EC keys. Common RSA values: 2048, 3072, 4096."
  type        = number
  default     = 2048
}

variable "key_opts" {
  description = "JSON web key operations permitted on the key."
  type        = list(string)
  default     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  validation {
    condition = length([
      for opt in var.key_opts : opt
      if !contains(["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"], opt)
    ]) == 0
    error_message = "key_opts must contain only decrypt, encrypt, sign, unwrapKey, verify, and wrapKey."
  }
}

variable "rotation_policy" {
  description = "Automatic key rotation policy. Set to null to disable."
  type = object({
    expire_after         = optional(string)
    notify_before_expiry = optional(string)
    automatic = optional(object({
      time_before_expiry = string
    }))
  })
  default = null
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
  description = "Tags applied to the key."
  type        = map(string)
  default     = {}
}
