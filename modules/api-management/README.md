# API Management Module

Terraform module to create an Azure API Management service with APIs, operations, optional products, and backends. Mirrors the AWS API Gateway HTTP API pattern.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_api_management` | Yes | API Management service |
| `azurerm_api_management_api` | Yes | One per entry in `apis` |
| `azurerm_api_management_api_operation` | No | One per entry in `operations` |
| `azurerm_api_management_product` | No | One per entry in `products` |
| `azurerm_api_management_product_api` | No | Links products to APIs |
| `azurerm_api_management_backend` | No | One per entry in `backends` |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### REST API with operations

```hcl
api_management_services = {
  public-api = {
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    name                = "my-company-apim-prod"
    publisher_name      = "My Company"
    publisher_email     = "platform@example.com"
    sku_name            = "Developer_1"

    apis = {
      orders = {
        display_name = "Orders API"
        path         = "orders"
        service_url  = "https://api.example.com/orders"
      }
    }

    operations = {
      list-orders = {
        api_key      = "orders"
        operation_id = "list-orders"
        display_name = "List orders"
        method       = "GET"
        url_template = "/"
      }
    }

    tags = { Purpose = "public-api" }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `name` | Service name | `string` | — | yes |
| `publisher_name` | Publisher name | `string` | — | yes |
| `publisher_email` | Publisher email | `string` | — | yes |
| `sku_name` | API Management SKU | `string` | `Developer_1` | no |
| `virtual_network_type` | VNet integration type | `string` | `None` | no |
| `subnet_id` | Subnet for VNet integration | `string` | `null` | no |
| `apis` | APIs map | `map(object)` | `{}` | yes |
| `operations` | Operations map | `map(object)` | `{}` | no |
| `products` | Products map | `map(object)` | `{}` | no |
| `backends` | Backends map | `map(object)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `service_id` | API Management service ID |
| `gateway_url` | Gateway URL |
| `developer_portal_url` | Developer portal URL |
| `api_ids` | API IDs by logical key |
| `operation_ids` | Operation IDs by logical key |
| `product_ids` | Product IDs by logical key |
| `backend_ids` | Backend IDs by logical key |

## Validation

The module includes **check** blocks for:

- At least one API required
- Operation `api_key` references
- Product `api_keys` references
- Subnet required for VNet integration
- Valid backend protocols and HTTP methods

## Coverage matrix

| Capability | Supported | Notes |
|------------|-----------|-------|
| REST APIs | Yes | OpenAPI import supported |
| Operations | Yes | Per-API HTTP operations |
| Products | Yes | Subscription gating |
| Backends | Yes | HTTP/SOAP backends |
| VNet integration | Yes | External/Internal |
| Managed identity | Yes | System or user-assigned |
| JWT authorizers | No | Configure via policies separately |
| Lambda proxy | No | Use Function App backend via URL |
| Custom domains | No | Add via separate resources |
| Consumption SKU | Yes | `Consumption_0` |

## Environment wiring

In `environments/prod`, use `api_management_services` with cross-module keys:

| Key | Resolves to |
|-----|-------------|
| `function_app_key` | Function App URL for backend `service_url` |
| `subnet_key` | Subnet ID for VNet integration |

## Notes

- Developer SKU is single-instance and not for production workloads.
- OpenAPI import uses the `import` block on each API definition.
- Policies, diagnostics, and custom domains can be added outside this module or extended later.
