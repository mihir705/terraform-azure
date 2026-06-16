output "cluster_id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_config" {
  description = "Raw kubeconfig for cluster admin access."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "Kubernetes API server host."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "cluster_identity" {
  description = "Cluster managed identity block."
  value       = azurerm_kubernetes_cluster.this.identity
}

output "node_resource_group" {
  description = "Auto-generated node resource group name."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "additional_node_pool_ids" {
  description = "Additional node pool IDs keyed by logical name."
  value       = { for name, pool in azurerm_kubernetes_cluster_node_pool.additional : name => pool.id }
}
