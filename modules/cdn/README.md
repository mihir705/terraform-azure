# CDN Module

Terraform module to create an Azure CDN profile and endpoint with a storage account origin. Optionally creates a private origin storage account. Mirrors the AWS CloudFront + S3 origin pattern.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_cdn_profile` | Yes | CDN profile (Standard Microsoft by default) |
| `azurerm_cdn_endpoint` | Yes | CDN endpoint with storage origin |
| `azurerm_storage_account` | No | Created when `create_origin_storage_account = true` |
| `azurerm_cdn_endpoint_custom_domain` | No | One per entry in `custom_domains` |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Static site with managed origin storage account

```hcl
cdn_profiles = {
  static-site = {
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    name                = "my-company-cdn-prod"
    endpoint_name       = "static-site"

    origin_storage_account_name = "mycompanystaticprod"

    tags = {
      Purpose = "static-site"
    }
  }
}
```

After `terraform apply`, upload site files to the origin storage account blob container and configure CDN origin path as needed.

Access the site at `https://<endpoint_fqdn>` from module outputs.

### Existing storage account as origin

```hcl
cdn_profiles = {
  static-site = {
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    name                = "my-company-cdn-prod"
    endpoint_name       = "static-site"

    create_origin_storage_account      = false
    existing_origin_storage_account_name = "mycompanystaticprod"
    storage_account_key                  = "static-site"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `name` | CDN profile name | `string` | — | yes |
| `endpoint_name` | CDN endpoint name | `string` | — | yes |
| `sku_name` | CDN SKU | `string` | `Standard_Microsoft` | no |
| `create_origin_storage_account` | Create origin storage account | `bool` | `true` | no |
| `origin_storage_account_name` | Origin storage account name | `string` | `null` | no* |
| `existing_origin_storage_account_name` | Existing origin account | `string` | `null` | no* |
| `origin_path` | Origin path prefix | `string` | `""` | no |
| `origin_sas_token` | SAS token for private origins | `string` | `null` | no |
| `is_http_allowed` | Allow HTTP | `bool` | `false` | no |
| `is_https_allowed` | Allow HTTPS | `bool` | `true` | no |
| `querystring_caching_behaviour` | Query string caching | `string` | `IgnoreQueryString` | no |
| `optimization_type` | CDN optimization type | `string` | `GeneralWebDelivery` | no |
| `geo_filter` | Geo filter object | `object` | `null` | no |
| `custom_domains` | Custom domains map | `map(object)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

\* Provide `origin_storage_account_name` when creating the origin account, or `existing_origin_storage_account_name` when reusing one.

## Outputs

| Name | Description |
|------|-------------|
| `profile_id` | CDN profile ID |
| `profile_name` | CDN profile name |
| `endpoint_id` | CDN endpoint ID |
| `endpoint_fqdn` | Public CDN FQDN |
| `origin_storage_account_id` | Origin storage account ID |
| `origin_storage_account_name` | Origin storage account name |
| `origin_storage_account_created` | Whether origin account was created |
| `custom_domain_ids` | Custom domain IDs by logical key |

## Validation

The module includes **check** blocks for:

- Origin storage account name requirements
- Existing origin account requirements
- At least one of HTTP/HTTPS allowed

## Coverage matrix

| Capability | Supported | Notes |
|------------|-----------|-------|
| CDN profile + endpoint | Yes | Standard Microsoft default |
| Storage account origin | Yes | Create or reference existing |
| Custom domains | Yes | DNS validation required separately |
| Geo filtering | Yes | `geo_filter` object |
| Private blob origin | Partial | Use `origin_sas_token` or configure separately |
| WAF integration | No | Use Azure Front Door for advanced WAF |
| Lambda@Edge | No | Use Azure Functions + Front Door rules |
| OAC-style bucket policy | No | Azure uses SAS or RBAC on storage |

## Environment wiring

In `environments/prod`, use `cdn_profiles` with cross-module keys:

| Key | Resolves to |
|-----|-------------|
| `storage_account_key` | Storage account name from storage-account module |

## Notes

- For private blob origins, configure a SAS token or use Azure Front Door with managed identity to storage.
- Custom domains require DNS CNAME validation after apply.
- Azure Front Door Standard/Premium offers more features than classic CDN; this module uses `azurerm_cdn_profile` + `azurerm_cdn_endpoint` as the CloudFront equivalent.
- Upload static assets to blob storage after the origin account is created.
