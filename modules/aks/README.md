# AKS Module

Terraform module to create an Azure Kubernetes Service (AKS) cluster with a default node pool, optional additional node pools, Azure CNI or kubenet networking, managed identity, and Azure RBAC.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_kubernetes_cluster` | Yes | AKS cluster with default node pool |
| `azurerm_kubernetes_cluster_node_pool` | No | One per `additional_node_pools` entry |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |
| [Random Provider](https://registry.terraform.io/providers/hashicorp/random/latest) | >= 3.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples.

### Cluster with Azure CNI

```hcl
aks_clusters = {
  platform = {
    name               = "my-company-aks-prod"
    resource_group_key = "app"
    dns_prefix         = "mycompanyprod"
    vnet_key           = "main"

    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"

    network_plugin = "azure"
    network_policy = "azure"

    default_node_pool = {
      vm_size             = "Standard_D2s_v3"
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 5
    }

    tags = { Purpose = "platform" }
  }
}
```

## Environment-level wiring

| Field | Resolves from |
|-------|----------------|
| `resource_group_key` | Resource group module |
| `vnet_key` | All private subnet IDs from VNet module (or set `subnet_ids` explicitly) |
| `service_cidr` / `dns_service_ip` | Must not overlap the VNet address space |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Cluster name | `string` | — | yes |
| `resource_group_name` | Resource group | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `dns_prefix` | API server DNS prefix | `string` | — | yes |
| `subnet_ids` | Cluster subnet IDs | `list(string)` | — | yes |
| `default_node_pool` | Default pool config | `object` | — | yes |
| `network_plugin` | `azure` or `kubenet` | `string` | `azure` | no |
| `azure_rbac_enabled` | Enable Azure RBAC | `bool` | `true` | no |
| `additional_node_pools` | Extra node pools | `map(object)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | AKS cluster ID |
| `kube_config` | Raw kubeconfig (sensitive) |
| `oidc_issuer_url` | OIDC issuer for workload identity |
| `node_resource_group` | Node resource group name |

## Notes

- **Azure CNI** is the default network plugin; use `network_policy = "azure"` or `"calico"` with Azure CNI.
- Default node pool supports cluster autoscaler via `enable_auto_scaling`.
- Set `private_cluster_enabled = true` for API server private endpoint only.
