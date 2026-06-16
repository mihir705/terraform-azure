# NSG Module

Terraform module to create an Azure Network Security Group with separate ingress and egress rules, mirroring the AWS `security-group` module pattern.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_network_security_group` | Yes | Core NSG |
| `azurerm_network_security_rule` | No | One per expanded ingress/egress rule; defaults to all outbound IPv4 |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Basic NSG with VNet integration

```hcl
network_security_groups = {
  app = {
    name               = "my-company-app-prod"
    resource_group_key = "main"
    vnet_key           = "main"
    description        = "Application instance NSG"

    ingress_rules = [
      {
        description            = "HTTP from VNet"
        protocol               = "tcp"
        destination_port_range = "8080"
        source_address_prefix  = "10.0.0.0/16"
      }
    ]

    tags = {
      Purpose = "app"
    }
  }
}
```

### Allow traffic from another NSG (Application Security Group recommended)

Azure NSG rules do not reference other NSG IDs directly. Use Application Security Groups (`source_application_security_group_ids`) or CIDR prefixes. The `referenced_network_security_group_id` field is accepted for API parity with AWS and maps to the `VirtualNetwork` service tag as a fallback — prefer ASGs for precise NSG-to-NSG style rules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | NSG name | `string` | — | yes |
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `vnet_id` | VNet ID (optional, for wiring) | `string` | `null` | no |
| `description` | Description | `string` | auto | no |
| `ingress_rules` | Inbound rules | `list(object)` | `[]` | no |
| `egress_rules` | Outbound rules | `list(object)` | all outbound IPv4 | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

### Rule object fields

| Field | Description |
|-------|-------------|
| `protocol` | `tcp`, `udp`, `icmp`, `-1`, or Azure names (`Tcp`, `Udp`, `*`) |
| `destination_port_range` | Required for `tcp` and `udp` (Azure port range syntax) |
| `source_address_prefix` / `source_address_prefixes` | Source CIDR(s) |
| `destination_address_prefix` / `destination_address_prefixes` | Destination CIDR(s) for egress |
| `source_application_security_group_ids` | Source ASG IDs |
| `destination_application_security_group_ids` | Destination ASG IDs |
| `referenced_network_security_group_id` | AWS parity; prefer ASGs in Azure |
| `self_reference` | AWS parity; prefer ASGs in Azure |

## Outputs

| Name | Description |
|------|-------------|
| `network_security_group_id` | NSG ID |
| `network_security_group_name` | NSG name |
| `security_group_id` | AWS-compatible alias |
| `ingress_rule_ids` | Ingress rule IDs |
| `egress_rule_ids` | Egress rule IDs |

## Design notes

- **Separate rule resources**: Each CIDR, ASG, or expanded target becomes its own `azurerm_network_security_rule`.
- **Default egress**: Allows all outbound IPv4 when `egress_rules` is not set. Set `egress_rules = []` for no egress.
- **VNet integration**: Use `vnet_key` in the environment stack to resolve `vnet_id` from the VNet module (mirrors AWS `vpc_key`).
- **Priority**: Auto-assigned from `100 + rule index` when not specified. Must be unique per direction (100–4096).

## Common workflow

1. Create VNet.
2. Create NSGs with `vnet_key = "main"`.
3. Reference `network_security_group_id` outputs in Function App VNet config, Virtual Machines, PostgreSQL, or Load Balancer NSG associations.
