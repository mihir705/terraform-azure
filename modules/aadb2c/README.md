# Azure AD B2C Module

Terraform module to create an Azure AD B2C tenant directory. Mirrors the AWS Cognito user pool pattern at the directory level.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_aadb2c_directory` | Yes | B2C tenant directory |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

```hcl
aadb2c_directories = {
  customer-auth = {
    resource_group_name = "my-company-rg-prod"
    country_code        = "US"
    display_name        = "My Company Customer Auth"
    domain_name         = "mycompanycustomers"
    data_residency      = "United States"

    tags = { Purpose = "customer-auth" }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Resource group name | `string` | — | yes |
| `country_code` | ISO country code | `string` | — | yes |
| `display_name` | Tenant display name | `string` | — | yes |
| `domain_name` | Domain prefix | `string` | — | yes |
| `data_residency` | Data residency region | `string` | `United States` | no |
| `sku_name` | Premium SKU | `string` | `PremiumP1` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `tenant_id` | B2C tenant ID |
| `domain_name` | Tenant domain name |
| `directory_id` | Directory resource ID |

## Terraform limitations

B2C tenant **creation** is supported via `azurerm_aadb2c_directory`. The following Cognito-equivalent features have **limited or no** Terraform support and typically require the Azure Portal, Microsoft Graph API, or the `azuread` provider scoped to the B2C tenant:

| Feature | Terraform support | Workaround |
|---------|-------------------|------------|
| B2C directory | Yes | This module |
| User flows (sign-up/sign-in) | No native resource | Azure Portal or Graph API |
| Custom policies (Identity Experience Framework) | Partial | `azurerm_aadb2c_trust_framework_policy` for XML policies only |
| App registrations in B2C tenant | Partial | `azuread` provider with B2C tenant alias |
| Social/enterprise IdP connectors | No | Azure Portal |
| Custom domains | No | Azure Portal / CLI |
| Branding / UI customization | No | Azure Portal |
| User pool groups / attributes | Partial | `azuread` resources in B2C tenant context |

After directory creation:

1. Switch to the B2C tenant in Azure Portal (`tenant_id` output).
2. Create user flows and app registrations manually or via `azuread` provider with a provider alias targeting the B2C tenant.
3. Link custom domains and identity providers in the portal.

## Notes

- B2C directories bill separately from Azure AD workforce tenants.
- Directory creation can take several minutes.
- Only one B2C tenant is allowed per subscription in many scenarios — verify subscription limits.
