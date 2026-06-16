# Function App Module

Terraform module to create an Azure Function App (Linux or Windows) with an App Service plan, storage account, Application Insights, optional VNet integration, managed identity, and zip deployment support.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_service_plan` | No | Created when `service_plan_id` is null |
| `azurerm_storage_account` | No | Created when `storage_account_id` is null |
| `azurerm_application_insights` | No | Created when `create_application_insights = true` |
| `azurerm_linux_function_app` / `azurerm_windows_function_app` | Yes | Based on `os_type` |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |
| [Random Provider](https://registry.terraform.io/providers/hashicorp/random/latest) | >= 3.0 |
| [Archive Provider](https://registry.terraform.io/providers/hashicorp/archive/latest) | >= 2.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Linux consumption function

```hcl
function_apps = {
  api-handler = {
    name                = "my-company-api-prod"
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    os_type             = "Linux"
    service_plan_sku    = "Y1"
    runtime_name        = "python"
    runtime_version     = "3.12"
    package_source_dir  = "function-src/api-handler"

    app_settings = {
      ENV = "prod"
    }

    tags = { Purpose = "api-handler" }
  }
}
```

### Premium plan with VNet integration

```hcl
function_apps = {
  private-processor = {
    name                = "my-company-processor-prod"
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    service_plan_sku    = "EP1"

    runtime_name    = "python"
    runtime_version = "3.12"

    vnet_integration = {
      subnet_id = module.vnet["main"].subnet_ids["functions"]
    }

    identity = {
      type = "SystemAssigned"
    }

    tags = { Purpose = "private-processor" }
  }
}
```

## Environment-level wiring

| Field | Resolves from |
|-------|----------------|
| `vnet_key` + `subnet_key` | Virtual network module subnets |
| `identity_ids` | User-assigned identity module |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Function app name | `string` | — | yes |
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `os_type` | Linux or Windows | `string` | `Linux` | no |
| `service_plan_sku` | Y1 consumption or EP* premium | `string` | `Y1` | no |
| `runtime_name` / `runtime_version` | Application stack | `string` | `null` | yes* |
| `app_settings` | Function app settings | `map(string)` | `{}` | no |
| `identity` | Managed identity | `object` | SystemAssigned | no |
| `vnet_integration` | Regional VNet integration | `object` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `function_app_id` | Function app resource ID |
| `function_app_name` | Function app name |
| `default_hostname` | Default hostname |
| `identity` | Managed identity block |
| `service_plan_id` | App Service plan ID |
| `storage_account_id` | Storage account ID |

## Notes

- **Consumption (Y1)** disables `always_on`; premium SKUs support VNet integration and pre-warmed instances.
- Use `package_source_dir` for automatic zip packaging via the archive provider.
- When referencing an existing storage account, set `storage_account_id` and `storage_account_name`.
