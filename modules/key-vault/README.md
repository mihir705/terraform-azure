# Key Vault Module

Terraform module to create and manage an Azure Key Vault with RBAC or access policy authorization, network ACLs, and purge protection. This is the vault container prerequisite for secrets and keys.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_key_vault` | Yes | Core Key Vault |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### RBAC-enabled vault (recommended)

Assign Azure RBAC roles such as `Key Vault Secrets Officer` and `Key Vault Crypto Officer` separately after the vault is created.

```hcl
module "app_vault" {
  source = "./modules/key-vault"

  resource_group_name = "rg-mycompany-app-prod"
  location            = "eastus"
  name                = "kv-mycompany-app-prod"

  enable_rbac_authorization = true
  purge_protection_enabled  = true

  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["203.0.113.10"]
  }

  tags = {
    Environment = "prod"
    Purpose     = "application-secrets"
  }
}
```

### Access policy mode

Use when RBAC is not enabled in your subscription or for legacy compatibility.

```hcl
data "azurerm_client_config" "current" {}

module "legacy_vault" {
  source = "./modules/key-vault"

  resource_group_name = "rg-mycompany-app-prod"
  location            = "eastus"
  name                = "kv-mycompany-legacy-prod"

  enable_rbac_authorization = false

  access_policies = [
    {
      object_id = data.azurerm_client_config.current.object_id
      secret_permissions = [
        "Get",
        "List",
        "Set",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
      ]
      key_permissions = [
        "Get",
        "List",
        "Create",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
      ]
    }
  ]

  tags = {
    Purpose = "legacy-vault"
  }
}
```

### Premium SKU for HSM-backed keys

```hcl
module "hsm_vault" {
  source = "./modules/key-vault"

  resource_group_name = "rg-mycompany-security-prod"
  location            = "eastus"
  name                = "kv-mycompany-hsm-prod"
  sku_name            = "premium"

  tags = {
    Purpose = "hsm-keys"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Resource group name | `string` | n/a | yes |
| `location` | Azure region | `string` | n/a | yes |
| `name` | Key Vault name | `string` | n/a | yes |
| `tenant_id` | Azure AD tenant ID | `string` | current client | no |
| `sku_name` | Vault SKU (`standard` or `premium`) | `string` | `"standard"` | no |
| `soft_delete_retention_days` | Soft-delete retention (`7-90`) | `number` | `90` | no |
| `purge_protection_enabled` | Enable purge protection | `bool` | `true` | no |
| `enable_rbac_authorization` | Use Azure RBAC instead of access policies | `bool` | `true` | no |
| `enabled_for_disk_encryption` | Allow disk encryption usage | `bool` | `false` | no |
| `enabled_for_deployment` | Allow VM certificate retrieval | `bool` | `false` | no |
| `enabled_for_template_deployment` | Allow ARM template secret retrieval | `bool` | `false` | no |
| `access_policies` | Vault access policies when RBAC is disabled | `list(object)` | `[]` | no |
| `network_acls` | Network ACL configuration. Set to `null` to allow all networks | `object` | deny by default | no |
| `tags` | Tags applied to the Key Vault | `map(string)` | `{}` | no |

### `access_policies` object

```hcl
access_policies = [
  {
    tenant_id               = optional(string)
    object_id               = string
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }
]
```

### `network_acls` object

```hcl
network_acls = {
  bypass                     = optional(string, "AzureServices")
  default_action             = optional(string, "Deny")
  ip_rules                   = optional(list(string), [])
  virtual_network_subnet_ids = optional(list(string), [])
}
```

## Outputs

| Name | Description |
|------|-------------|
| `key_vault_id` | ID of the Key Vault |
| `key_vault_name` | Name of the Key Vault |
| `key_vault_uri` | URI of the Key Vault |
| `tenant_id` | Azure AD tenant ID |
| `rbac_authorization_enabled` | Whether RBAC authorization is enabled |
| `purge_protection_enabled` | Whether purge protection is enabled |
| `network_acls_enabled` | Whether network ACLs are configured |

## Security defaults

- Azure RBAC authorization enabled by default
- Purge protection enabled by default
- Soft-delete retention defaults to 90 days
- Network ACLs default to deny with AzureServices bypass
- Deployment, disk encryption, and template deployment integrations disabled by default

## Validation rules

- `name` must be 3-24 alphanumeric characters and hyphens
- `sku_name` must be `standard` or `premium`
- `soft_delete_retention_days` must be between 7 and 90
- `access_policies` cannot be used when `enable_rbac_authorization = true`
- At least one `access_policy` is required when RBAC is disabled

## Example output usage

```hcl
module "app_vault" {
  source = "./modules/key-vault"

  resource_group_name = "rg-mycompany-app-prod"
  location            = "eastus"
  name                = "kv-mycompany-app-prod"
}

module "database_password" {
  source = "./modules/key-vault-secret"

  resource_group_name = "rg-mycompany-app-prod"
  location            = "eastus"
  name                = "database-password"

  vault_key = {
    name = module.app_vault.key_vault_name
  }
}
```

## What this module does not manage

- Azure RBAC role assignments
- Private endpoints
- Key Vault secrets or keys (use `key-vault-secret` and `key-vault-key` modules)
- Diagnostic settings
