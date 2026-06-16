output "network_security_group_id" {
  description = "Network Security Group ID."
  value       = azurerm_network_security_group.nsg.id
}

output "network_security_group_name" {
  description = "Network Security Group name."
  value       = azurerm_network_security_group.nsg.name
}

output "network_security_group_resource_group_name" {
  description = "Resource group containing the NSG."
  value       = var.resource_group_name
}

output "network_security_group_location" {
  description = "Azure region of the NSG."
  value       = var.location
}

output "vnet_id" {
  description = "Virtual network ID passed to the module. Null when not provided."
  value       = var.vnet_id
}

output "ingress_rule_ids" {
  description = "Ingress rule resource IDs keyed by generated rule key."
  value       = { for key, rule in azurerm_network_security_rule.ingress : key => rule.id }
}

output "egress_rule_ids" {
  description = "Egress rule resource IDs keyed by generated rule key."
  value       = { for key, rule in azurerm_network_security_rule.egress : key => rule.id }
}

# AWS-compatible aliases
output "security_group_id" {
  description = "Alias for network_security_group_id (AWS security-group compatibility)."
  value       = azurerm_network_security_group.nsg.id
}

output "security_group_name" {
  description = "Alias for network_security_group_name (AWS security-group compatibility)."
  value       = azurerm_network_security_group.nsg.name
}
