output "vnet_id" {
  description = "Virtual network resource ID."
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_resource_group_name" {
  description = "Resource group containing the virtual network."
  value       = var.resource_group_name
}

output "address_space" {
  description = "Virtual network address space."
  value       = azurerm_virtual_network.vnet.address_space
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by logical name."
  value       = { for key, subnet in azurerm_subnet.public : key => subnet.id }
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by logical name."
  value       = { for key, subnet in azurerm_subnet.private : key => subnet.id }
}

output "public_subnet_address_prefixes" {
  description = "Public subnet address prefixes keyed by logical name."
  value       = { for key, subnet in azurerm_subnet.public : key => subnet.address_prefixes[0] }
}

output "private_subnet_address_prefixes" {
  description = "Private subnet address prefixes keyed by logical name."
  value       = { for key, subnet in azurerm_subnet.private : key => subnet.address_prefixes[0] }
}

output "availability_zones" {
  description = "Availability zones used by public and private subnets."
  value = distinct(concat(
    [for subnet in var.public_subnets : subnet.availability_zone],
    [for subnet in var.private_subnets : subnet.availability_zone],
  ))
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs keyed by availability zone."
  value       = { for az, nat in azurerm_nat_gateway.nat : az => nat.id }
}

output "nat_public_ip_addresses" {
  description = "NAT Gateway public IP addresses keyed by availability zone."
  value       = { for az, pip in azurerm_public_ip.nat : az => pip.ip_address }
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = azurerm_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs keyed by subnet name or default."
  value       = { for key, table in azurerm_route_table.private : key => table.id }
}

output "public_nacl_id" {
  description = "Public subnet NSG ID. Null when create_public_nacl is false."
  value       = try(azurerm_network_security_group.public[0].id, null)
}

output "private_nacl_id" {
  description = "Private subnet NSG ID. Null when create_private_nacl is false."
  value       = try(azurerm_network_security_group.private[0].id, null)
}

output "nat_gateway_enabled" {
  description = "Whether NAT gateways were created."
  value       = var.enable_nat_gateway
}

output "single_nat_gateway" {
  description = "Whether a single shared NAT gateway is used."
  value       = var.enable_nat_gateway && var.single_nat_gateway && !var.one_nat_gateway_per_az
}
