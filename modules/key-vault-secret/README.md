# Key Vault Secret Module

Terraform module to create and manage a secret in an existing Azure Key Vault with optional initial value, generated passwords, and lifecycle controls. This is the Azure equivalent of the AWS Secrets Manager module.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_key_vault_secret` | Yes | Core secret |
| `random_password` | No | Created when `generate_random_password` is set |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |
| [Random Provider](https://registry.terraform.io/providers/hashicorp/random/latest) | >= 3.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Empty secret shell (value set outside Terraform)

Azure Key Vault requires a value at creation time. When no value is supplied, the module creates a placeholder and ignores future value changes so the secret can be updated in the Azure Portal or by CI/CD.

```hcl
module "app_config" {
  source = "./modules/key-vault-secret"

  resource_group_name = "rg-mycompany-app-prod"
  location            = "eastus"
  name                = "app-config"

  vault_key = {
    name = module.app_vault.key_vault_name
  }

  tags = {
    Environment = "prod"
    Purpose     = "app-config"
  }
}
```

### Secret with initial string value

```hcl
module "database_credentials" {
  source = "./modules/key-vault-secret"

  resource_group_name = "rg-mycompany-app-prod"
  location            = "eastus"
  name                = "database-credentials"

  vault_key = {
    name = module.app_vault.key_vault_name
  }

  secret_value = jsonencode({
    username = "db_user"
    password = "CHANGE_ME"
  })

  tags = {
    Purpose = "database-credentials"
  }
}
```

### Generated random password

```hcl
module "database_credentials" {
  source = "./modules/key-vault-secret"

  resource_group_name = "rg-mycompany-app-prod"
  location            = "eastus"
  name                = "database-credentials"

  vault_key = {
    name = module.app_vault.key_vault_name
  }

  generate_random_password = {
    length   = 32
    username = "db_admin"
  }

  ignore_secret_changes = true

  tags = {
    Purpose = "database-credentials"
  }
}
```

### Reference vault by resource ID

```hcl
module "api_key" {
  source = "./modules/key-vault-secret"

  resource_group_name = "rg-mycompany-app-prod"
  location            = "eastus"
  name                = "api-key"

  key_vault_id  = module.app_vault.key_vault_id
  secret_value  = "REPLACE_WITH_REAL_API_KEY"
  content_type  = "text/plain"
  ignore_secret_changes = true

  tags = {
    Purpose = "api-key"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Resource group for vault lookup | `string` | n/a | yes |
| `location` | Azure region (interface consistency) | `string` | n/a | yes |
| `name` | Secret name | `string` | n/a | yes |
| `key_vault_id` | Full Key Vault resource ID | `string` | `null` | no |
| `vault_key` | Key Vault reference by name | `object` | `null` | no |
| `secret_value` | Secret value as UTF-8 text | `string` | `null` | no |
| `generate_random_password` | Generate and store a random password | `object` | `null` | no |
| `ignore_secret_changes` | Ignore secret value changes after create | `bool` | `false` | no |
| `content_type` | Secret content type | `string` | `null` | no |
| `expiration_date` | Expiration date (RFC3339) | `string` | `null` | no |
| `not_before_date` | Not-before date (RFC3339) | `string` | `null` | no |
| `tags` | Tags applied to the secret | `map(string)` | `{}` | no |

Exactly one of `key_vault_id` or `vault_key` is required.

### `vault_key` object

```hcl
vault_key = {
  name                = string
  resource_group_name = optional(string)
}
```

When `resource_group_name` is omitted, the module uses `resource_group_name` from the module inputs.

### `generate_random_password` object

```hcl
generate_random_password = {
  length           = optional(number, 32)
  special          = optional(bool, true)
  override_special = optional(string, "!#$%&*()-_=+[]{}<>:?")
  username         = optional(string, null)
}
```

When `username` is set, the secret value is stored as JSON:

```json
{"username":"db_admin","password":"<generated>"}
```

## Outputs

| Name | Description |
|------|-------------|
| `secret_id` | ID of the Key Vault secret |
| `secret_name` | Name of the secret |
| `secret_version` | Current secret version |
| `secret_resource_id` | Full Azure resource ID |
| `key_vault_id` | ID of the containing Key Vault |
| `random_password_generated` | Whether Terraform generated the value |
| `secret_value_managed` | Whether Terraform manages the secret value |

Secret values are never exported as outputs.

## Security defaults and recommendations

- Secret values are marked `sensitive` in Terraform
- Do not commit real secret values to git
- Prefer `ignore_secret_changes = true` when values are rotated outside Terraform
- Assign Key Vault RBAC roles to workloads instead of embedding secrets in configuration

## Validation rules

- Exactly one of `key_vault_id` or `vault_key` must be set
- Only one of `secret_value` or `generate_random_password` may be set

## What this module does not manage

- Key Vault creation (use the `key-vault` module)
- Key Vault keys or certificates
- Automatic rotation functions
- RBAC role assignments
