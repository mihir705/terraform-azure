# RBAC Role Module

Terraform module combining AWS IAM role, policy, and user patterns using Azure RBAC, managed identities, and service principals.

## Identity types

| `identity_type` | Creates |
|-----------------|---------|
| `user_assigned` | User-assigned managed identity (default) |
| `service_principal` | Azure AD application + service principal |
| `existing_principal` | Role assignments only for an existing principal |

## Usage

```hcl
rbac_roles = {
  app-identity = {
    name                = "app-identity-prod"
    resource_group_key  = "app"
    identity_type       = "user_assigned"

    role_assignments = {
      storage-contrib = {
        scope                = module.storage_account["app-data"].storage_account_id
        role_definition_name = "Storage Blob Data Contributor"
      }
    }
  }
}
```

See [terraform.tfvars.example](./terraform.tfvars.example).

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| azurerm | >= 3.100 |
| azuread | >= 2.50 |
