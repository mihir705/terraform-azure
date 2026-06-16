# VNet Module

Terraform module to create an Azure Virtual Network with public and private subnets, NAT Gateway, route tables, and optional subnet Network Security Groups (Azure equivalent of AWS Network ACLs).

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_virtual_network` | Yes | Core VNet |
| `azurerm_subnet` | Yes | Public and private subnets from input maps |
| `azurerm_route_table` | Yes | One public + one or more private route tables |
| `azurerm_subnet_route_table_association` | Yes | Associates subnets with route tables |
| `azurerm_public_ip` | No | Created when `enable_nat_gateway = true` |
| `azurerm_nat_gateway` | No | Single NAT or one per zone |
| `azurerm_subnet_nat_gateway_association` | No | Associates NAT with private subnets |
| `azurerm_network_security_group` | No | Public and/or private subnet NSGs when enabled |
| `azurerm_network_security_rule` | No | NSG rules when subnet NSGs are enabled |
| `azurerm_subnet_network_security_group_association` | No | Associates NSGs with subnets |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Standard VNet — 2 public + 2 private subnets

```hcl
module "main_vnet" {
  source = "./modules/vnet"

  name                = "my-company-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_location
  address_space       = ["10.0.0.0/16"]

  public_subnets = {
    az-a = {
      availability_zone = "1"
      address_prefix    = "10.0.1.0/24"
    }
    az-b = {
      availability_zone = "2"
      address_prefix    = "10.0.2.0/24"
    }
  }

  private_subnets = {
    az-a = {
      availability_zone = "1"
      address_prefix    = "10.0.11.0/24"
    }
    az-b = {
      availability_zone = "2"
      address_prefix    = "10.0.12.0/24"
    }
  }

  tags = {
    Environment = "prod"
    Purpose     = "main-network"
  }
}
```

### Environment stack (prod)

```hcl
vnets = {
  main = {
    name                = "my-company-prod"
    resource_group_key  = "main"
    address_space       = ["10.0.0.0/16"]

    public_subnets = {
      az-a = { availability_zone = "1", address_prefix = "10.0.1.0/24" }
      az-b = { availability_zone = "2", address_prefix = "10.0.2.0/24" }
    }

    private_subnets = {
      az-a = { availability_zone = "1", address_prefix = "10.0.11.0/24" }
      az-b = { availability_zone = "2", address_prefix = "10.0.12.0/24" }
    }

    tags = { Purpose = "main-network" }
  }
}
```

Reference this VNet from other modules using `vnet_key = "main"` in the environment stack (mirrors AWS `vpc_key`).

## Architecture

```
                    Internet
                        |
                 Public Route Table
                        |
        +---------------+---------------+
        |                               |
   Public Subnet A              Public Subnet B
   (10.0.1.0/24)                (10.0.2.0/24)
   Zone 1                        Zone 2
                        |
              NAT Gateway (optional)
                        |
   Private Subnet A              Private Subnet B
   (10.0.11.0/24)                (10.0.12.0/24)
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name prefix for resources | `string` | — | yes |
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `address_space` | VNet address space | `list(string)` | — | yes |
| `public_subnets` | Public subnet map | `map(object)` | — | yes |
| `private_subnets` | Private subnet map | `map(object)` | — | yes |
| `enable_nat_gateway` | Create NAT gateway(s) | `bool` | `true` | no |
| `single_nat_gateway` | One shared NAT (cost saving) | `bool` | `true` | no |
| `one_nat_gateway_per_az` | NAT per zone (HA) | `bool` | `false` | no |
| `create_public_nacl` | Create public subnet NSG | `bool` | `true` | no |
| `create_private_nacl` | Create private subnet NSG | `bool` | `true` | no |
| `public_nacl_ingress_rules` | Public NSG ingress rules | `list(object)` | HTTP/HTTPS + ephemeral | no |
| `public_nacl_egress_rules` | Public NSG egress rules | `list(object)` | Allow all | no |
| `private_nacl_ingress_rules` | Private NSG ingress rules | `list(object)` | VNet CIDR | no |
| `private_nacl_egress_rules` | Private NSG egress rules | `list(object)` | Allow all | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | Virtual network ID |
| `vnet_name` | Virtual network name |
| `address_space` | VNet address space |
| `public_subnet_ids` | Public subnet IDs by name |
| `private_subnet_ids` | Private subnet IDs by name |
| `nat_gateway_ids` | NAT Gateway IDs by zone |
| `nat_public_ip_addresses` | NAT public IPs by zone |
| `public_route_table_id` | Public route table ID |
| `private_route_table_ids` | Private route table IDs |
| `public_nacl_id` | Public subnet NSG ID |
| `private_nacl_id` | Private subnet NSG ID |

## Design notes

- **Public subnets** route `0.0.0.0/0` to the Internet via a dedicated route table.
- **Private subnets** use NAT Gateway associations for outbound internet access when enabled.
- **Single NAT** (default) uses one NAT gateway for all private subnets — lower cost, zone dependency for egress.
- **NAT per zone** sets `single_nat_gateway = false` and `one_nat_gateway_per_az = true` for HA.
- **Subnet NSGs** mirror the AWS NACL pattern. Azure NSGs are stateful; rules use Azure protocol names (`Tcp`, `Udp`, `*`).
- Per-resource NSGs are not included — add workload NSGs with the `nsg` module.

## NAT gateway cost note

NAT Gateways incur hourly and data processing charges. Use `single_nat_gateway = true` (default) for dev/staging; use `one_nat_gateway_per_az = true` for production HA when required.
