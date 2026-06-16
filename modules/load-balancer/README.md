# Load Balancer Module

Terraform module to create an Azure Load Balancer (Standard SKU) with frontend IP, backend pools, health probes, and L4 rules — mirroring the AWS `nlb` module.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_lb` | Yes | Standard SKU Layer-4 load balancer |
| `azurerm_lb_backend_address_pool` | Yes | One per `target_groups` entry |
| `azurerm_lb_probe` | Yes | One health probe per target group |
| `azurerm_lb_rule` | Yes | One per `listeners` entry |
| `azurerm_public_ip` | No | Created for internet-facing load balancers |
| `azurerm_lb_backend_address_pool_address` | No | Created when `targets` are defined |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples.

### Internet-facing load balancer with TCP listener

```hcl
load_balancers = {
  public = {
    name               = "my-company-public-lb-prod"
    resource_group_key = "main"
    vnet_key           = "main"

    target_groups = {
      app = {
        port     = 8080
        protocol = "Tcp"
      }
    }

    listeners = {
      tcp = {
        port             = 8080
        protocol         = "Tcp"
        target_group_key = "app"
      }
    }

    tags = {
      Purpose = "public-lb"
    }
  }
}
```

When `vnet_key` is set, the environment stack resolves `vnet_id` and subnet IDs from the VNet module — **public subnets** for internet-facing load balancers and **private subnets** when `internal = true`.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Load balancer name | `string` | — | yes |
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `vnet_id` | VNet ID for backend pool addresses | `string` | — | yes |
| `subnet_ids` | Subnet IDs for internal frontends | `list(string)` | `[]` | no |
| `internal` | Internal load balancer | `bool` | `false` | no |
| `target_groups` | Backend pool map | `map(object)` | — | yes |
| `listeners` | L4 rule map | `map(object)` | — | yes |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `load_balancer_id` | Load balancer ID |
| `load_balancer_public_ip_address` | Public frontend IP |
| `backend_pool_ids` | Backend pool IDs by key |
| `probe_ids` | Health probe IDs |
| `rule_ids` | Load balancing rule IDs |

## Notes

- Standard SKU supports TCP and UDP load balancing with health probes.
- Register IP targets via `targets` on each target group using private IP addresses in the VNet.
- Internal load balancers require `subnet_ids` or `frontend_subnet_id`.
- Attach NSGs at the subnet or NIC level in Azure (unlike AWS NLB optional SG attachment).
