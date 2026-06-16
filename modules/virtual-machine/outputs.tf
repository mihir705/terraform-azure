output "vm_id" {
  description = "Virtual machine resource ID."
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Virtual machine name."
  value       = azurerm_linux_virtual_machine.this.name
}

output "private_ip_address" {
  description = "Primary private IP address."
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address when create_public_ip is true."
  value       = try(azurerm_public_ip.this[0].ip_address, null)
}

output "network_interface_id" {
  description = "Network interface ID."
  value       = azurerm_network_interface.this.id
}

output "identity" {
  description = "Managed identity block for the VM."
  value       = azurerm_linux_virtual_machine.this.identity
}

output "admin_password" {
  description = "Generated administrator password when generate_password is used."
  value       = try(random_password.admin[0].result, null)
  sensitive   = true
}

output "os_disk_id" {
  description = "OS managed disk ID."
  value       = try(azurerm_linux_virtual_machine.this.os_disk[0].name, null)
}

output "data_disk_ids" {
  description = "Data managed disk IDs keyed by logical name."
  value       = { for key, disk in azurerm_managed_disk.data : key => disk.id }
}
