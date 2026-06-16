# Container Registry Module

Terraform module to create an Azure Container Registry (ACR) with configurable SKU, admin disabled by default, optional geo-replication, retention policy, and network rules.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_container_registry` | Yes | Azure Container Registry |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |
| [Random Provider](https://registry.terraform.io/providers/hashicorp/random/latest) | >= 3.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples.

### Standard registry with managed identity

```hcl
container_registries = {
  app = {
    name                = "mycompanyprod"
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    sku                 = "Standard"
    admin_enabled       = false

    identity = {
      type = "SystemAssigned"
    }

    tags = { Purpose = "application-images" }
  }
}
```

### Premium registry with network rules and retention

```hcl
container_registries = {
  app = {
    name                = "mycompanyprod"
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    sku                 = "Premium"

    network_rule_set = {
      default_action = "Deny"
      virtual_network_rules = [
        {
          subnet_id = module.vnet["main"].subnet_ids["aks-a"]
        }
      ]
    }

    retention_policy = {
      days    = 30
      enabled = true
    }

    georeplications = [
      { location = "westus2" }
    ]

    tags = { Purpose = "application-images" }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Registry name (globally unique) | `string` | — | yes |
| `resource_group_name` | Resource group | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `sku` | Basic, Standard, or Premium | `string` | `Standard` | no |
| `admin_enabled` | Enable admin user | `bool` | `false` | no |
| `network_rule_set` | Network ACLs (Premium) | `object` | `null` | no |
| `georeplications` | Geo-replication (Premium) | `list(object)` | `[]` | no |
| `retention_policy_in_days` | Manifest retention (Premium) | `number` | `null` | no |
| `trust_policy_enabled` | Content trust (Premium) | `bool` | `false` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `registry_id` | Registry resource ID |
| `login_server` | Registry login server URL |
| `identity` | Managed identity block |

## Notes

- **Admin user** is disabled by default; prefer managed identity or AAD tokens for pull/push.
- Geo-replication, network rules, and retention policy require **Premium** SKU.
- Registry names must be globally unique, 5–50 lowercase alphanumeric characters.
