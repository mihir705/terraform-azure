output "load_balancer_id" {
  description = "Load balancer resource ID."
  value       = azurerm_lb.load_balancer.id
}

output "load_balancer_name" {
  description = "Load balancer name."
  value       = azurerm_lb.load_balancer.name
}

output "load_balancer_frontend_private_ip_address" {
  description = "Private frontend IP address when allocated."
  value       = try(azurerm_lb.load_balancer.frontend_ip_configuration[0].private_ip_address, null)
}

output "load_balancer_public_ip_address" {
  description = "Public IP address when an internet-facing load balancer is created."
  value       = var.internal ? null : try(azurerm_public_ip.frontend[0].ip_address, null)
}

output "public_ip_id" {
  description = "Public IP resource ID for the frontend. Null for internal load balancers."
  value       = var.internal ? null : coalesce(var.public_ip_address_id, try(azurerm_public_ip.frontend[0].id, null))
}

output "backend_pool_ids" {
  description = "Backend address pool IDs keyed by logical name."
  value       = { for key, pool in azurerm_lb_backend_address_pool.target_group : key => pool.id }
}

output "probe_ids" {
  description = "Health probe IDs keyed by target group name."
  value       = { for key, probe in azurerm_lb_probe.probe : key => probe.id }
}

output "rule_ids" {
  description = "Load balancing rule IDs keyed by listener name."
  value       = { for key, rule in azurerm_lb_rule.listener : key => rule.id }
}

output "cross_zone_load_balancing_enabled" {
  description = "Whether cross-zone load balancing is enabled on rules."
  value       = var.enable_cross_zone_load_balancing
}

output "load_balancer_arn" {
  description = "Load balancer resource ID (AWS ARN compatibility alias)."
  value       = azurerm_lb.load_balancer.id
}

output "load_balancer_dns_name" {
  description = "Public frontend IP address (AWS DNS name compatibility alias)."
  value       = var.internal ? try(azurerm_lb.load_balancer.frontend_ip_configuration[0].private_ip_address, null) : try(azurerm_public_ip.frontend[0].ip_address, null)
}

output "target_group_ids" {
  description = "Backend pool IDs keyed by logical name (AWS target group compatibility alias)."
  value       = { for key, pool in azurerm_lb_backend_address_pool.target_group : key => pool.id }
}

output "listener_ids" {
  description = "Load balancing rule IDs keyed by listener name (AWS listener compatibility alias)."
  value       = { for key, rule in azurerm_lb_rule.listener : key => rule.id }
}
