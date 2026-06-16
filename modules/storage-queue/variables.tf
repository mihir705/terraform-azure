variable "resource_group_name" {
  description = "Resource group name when creating a storage account."
  type        = string
}

variable "location" {
  description = "Azure region when creating a storage account."
  type        = string
}

variable "create_storage_account" {
  description = "Create a storage account for the queue. Set to false to use an existing account."
  type        = bool
  default     = true
}

variable "storage_account_name" {
  description = "Storage account name. Required when create_storage_account is true."
  type        = string
  default     = null
}

variable "existing_storage_account_name" {
  description = "Existing storage account name. Required when create_storage_account is false."
  type        = string
  default     = null
}

variable "existing_storage_account_resource_group_name" {
  description = "Resource group of the existing storage account. Defaults to resource_group_name."
  type        = string
  default     = null
}

variable "storage_account_tier" {
  description = "Storage account tier when created by this module."
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage replication type when the account is created by this module."
  type        = string
  default     = "LRS"
}

variable "name" {
  description = "Queue name. Required unless name_prefix is set."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || (length(var.name) >= 3 && length(var.name) <= 63)
    error_message = "name must be between 3 and 63 characters."
  }
}

variable "name_prefix" {
  description = "Creates a unique queue name with the given prefix. Cannot be combined with name."
  type        = string
  default     = null
}

variable "metadata" {
  description = "Queue metadata key/value pairs."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
