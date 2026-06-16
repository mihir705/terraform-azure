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

### Private cluster with Azure CNI

```hcl
aks_clusters = {
  platform = {
    name                = "my-company-aks-prod"
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    dns_prefix          = "mycompanyprod"
    vnet_key            = "main"
    subnet_keys         = ["aks-a", "aks-b"]

    network_plugin = "azure"
    network_policy = "azure"

    default_node_pool = {
      vm_size             = "Standard_D2s_v3"
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 5
    }

    azure_rbac_enabled = true
    admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]

    tags = { Purpose = "platform" }
  }
}
```

## Environment-level wiring

| Field | Resolves from |
|-------|----------------|
| `vnet_key` + `subnet_keys` | AKS subnet IDs from VNet module (min 1) |

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
