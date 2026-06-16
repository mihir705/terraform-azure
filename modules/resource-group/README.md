# Resource Group Module

Terraform module to create and manage an Azure resource group. This is the Azure-specific foundation module used to scope other resources in a region.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_resource_group` | Yes | Core resource group |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Basic resource group

```hcl
module "network" {
  source = "./modules/resource-group"

  resource_group_name = "rg-mycompany-network-prod"
  location            = "eastus"

  tags = {
    Environment = "prod"
    Purpose     = "network"
  }
}
```

### Shared application resource group

```hcl
module "app" {
  source = "./modules/resource-group"

  resource_group_name = "rg-mycompany-app-dev"
  location            = "eastus"

  tags = {
    Environment = "dev"
    Purpose     = "application"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Name of the Azure resource group | `string` | n/a | yes |
| `location` | Azure region for the resource group | `string` | n/a | yes |
| `tags` | Tags applied to the resource group | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Name of the resource group |
| `resource_group_id` | ID of the resource group |
| `location` | Azure region of the resource group |

## Example output usage

```hcl
module "app" {
  source = "./modules/resource-group"

  resource_group_name = "rg-mycompany-app-prod"
  location            = "eastus"
}

module "storage" {
  source = "./modules/storage-account"

  resource_group_name  = module.app.resource_group_name
  location             = module.app.location
  storage_account_name = "stmycompanyappprod"
}
```

## What this module does not manage

- Resource locks
- Role assignments at the resource group scope
- Management group hierarchy
