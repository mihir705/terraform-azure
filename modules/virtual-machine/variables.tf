variable "name" {
  description = "Virtual machine name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64
    error_message = "name must be between 1 and 64 characters."
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

variable "subnet_id" {
  description = "Subnet ID for the network interface. Resolved from vnet_key/subnet_key at the environment level."
  type        = string
}

variable "nsg_id" {
  description = "Network security group ID to associate with the NIC. Resolved from nsg_key at the environment level."
  type        = string
  default     = null
}

variable "size" {
  description = "Azure VM size (e.g. Standard_B2s)."
  type        = string

  validation {
    condition     = length(var.size) > 0
    error_message = "size is required."
  }
}

variable "admin_username" {
  description = "Administrator username for the VM."
  type        = string

  validation {
    condition     = length(var.admin_username) >= 1 && length(var.admin_username) <= 32
    error_message = "admin_username must be between 1 and 32 characters."
  }
}

variable "admin_password" {
  description = "Administrator password. Omit when using SSH key or generate_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "generate_password" {
  description = "Generate a random administrator password in Terraform."
  type = object({
    length           = optional(number, 32)
    special          = optional(bool, true)
    override_special = optional(string, "!#$%&*()-_=+[]{}<>:?")
  })
  default = null
}

variable "disable_password_authentication" {
  description = "Disable password authentication (SSH key only)."
  type        = bool
  default     = true
}

variable "admin_ssh_key" {
  description = "SSH public key configuration."
  type = object({
    username   = string
    public_key = string
  })
  default = null
}

variable "source_image_reference" {
  description = "Marketplace image reference. Required unless source_image_id is set."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = optional(string, "latest")
  })
  default = null
}

variable "source_image_id" {
  description = "Custom image ID. Cannot be combined with source_image_reference."
  type        = string
  default     = null
}

variable "availability_zone" {
  description = "Availability zone for the VM and managed disks."
  type        = string
  default     = null
}

variable "private_ip_address_allocation" {
  description = "Private IP allocation method: Dynamic or Static."
  type        = string
  default     = "Dynamic"

  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_address_allocation)
    error_message = "private_ip_address_allocation must be Dynamic or Static."
  }
}

variable "private_ip_address" {
  description = "Static private IP address when private_ip_address_allocation is Static."
  type        = string
  default     = null
}

variable "create_public_ip" {
  description = "Create and associate a public IP with the NIC."
  type        = bool
  default     = false
}

variable "public_ip_sku" {
  description = "Public IP SKU: Basic or Standard."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "public_ip_sku must be Basic or Standard."
  }
}

variable "public_ip_allocation_method" {
  description = "Public IP allocation method."
  type        = string
  default     = "Static"

  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "public_ip_allocation_method must be Static or Dynamic."
  }
}

variable "custom_data" {
  description = "Cloud-init/custom data script (base64 encoded automatically)."
  type        = string
  default     = null
}

variable "custom_data_base64" {
  description = "Base64-encoded custom data. Cannot be combined with custom_data."
  type        = string
  default     = null
}

variable "os_disk" {
  description = "OS managed disk configuration."
  type = object({
    caching                = optional(string, "ReadWrite")
    storage_account_type   = optional(string, "Premium_LRS")
    disk_size_gb           = optional(number)
    disk_encryption_set_id = optional(string)
  })
  default = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
}

variable "data_disks" {
  description = "Additional managed data disks keyed by logical name."
  type = map(object({
    lun                    = number
    caching                = optional(string, "None")
    storage_account_type   = optional(string, "Premium_LRS")
    disk_size_gb           = number
    create_option          = optional(string, "Empty")
    disk_encryption_set_id = optional(string)
  }))
  default = {}
}

variable "identity" {
  description = "Managed identity configuration."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}

variable "boot_diagnostics_storage_uri" {
  description = "Storage URI for boot diagnostics. Omit to disable boot diagnostics."
  type        = string
  default     = null
}

variable "enable_automatic_updates" {
  description = "Enable automatic platform updates."
  type        = bool
  default     = true
}

variable "patch_mode" {
  description = "Patch mode: AutomaticByPlatform, AutomaticByOS, or Manual."
  type        = string
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["AutomaticByPlatform", "AutomaticByOS", "Manual"], var.patch_mode)
    error_message = "patch_mode must be AutomaticByPlatform, AutomaticByOS, or Manual."
  }
}

variable "tags" {
  description = "Tags applied to VM and related resources."
  type        = map(string)
  default     = {}
}
