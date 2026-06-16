# Storage Account Module

Terraform module to create and manage an Azure Storage Account with secure defaults, optional blob containers, versioning, encryption, network rules, and lifecycle management. This is the Azure equivalent of the AWS S3 module.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_storage_account` | Yes | Core storage account |
| `azurerm_storage_container` | No | One per entry in `containers` |
| `azurerm_storage_account_network_rules` | No | Created when `network_rules` is set |
| `azurerm_storage_management_policy` | No | Created when `lifecycle_rules` is non-empty |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Basic storage account with containers

```hcl
module "app_data" {
  source = "./modules/storage-account"

  resource_group_name  = "rg-mycompany-app-prod"
  location             = "eastus"
  storage_account_name = "stmycompanyappprod"
  versioning_enabled   = true

  containers = {
    uploads = {
      access_type = "private"
    }
    logs = {
      access_type = "private"
    }
  }

  tags = {
    Environment = "prod"
    Purpose     = "application-data"
  }
}
```

### Network-restricted storage account

```hcl
module "secure_data" {
  source = "./modules/storage-account"

  resource_group_name  = "rg-mycompany-app-prod"
  location             = "eastus"
  storage_account_name = "stmycompanysecureprod"
  versioning_enabled   = true

  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = ["203.0.113.10"]
  }

  tags = {
    Purpose = "secure-data"
  }
}
```

### Customer-managed key encryption

Requires a Key Vault key and user-assigned managed identity with appropriate permissions on the vault and storage account.

```hcl
module "encrypted_data" {
  source = "./modules/storage-account"

  resource_group_name  = "rg-mycompany-app-prod"
  location             = "eastus"
  storage_account_name = "stmycompanyencprod"
  versioning_enabled   = true

  customer_managed_key = {
    key_vault_key_id          = module.app_key.key_id
    user_assigned_identity_id = azurerm_user_assigned_identity.storage.id
  }

  tags = {
    Purpose = "encrypted-data"
  }
}
```

### Lifecycle rules

```hcl
module "logs" {
  source = "./modules/storage-account"

  resource_group_name  = "rg-mycompany-logs-prod"
  location             = "eastus"
  storage_account_name = "stmycompanylogsprod"
  versioning_enabled   = true

  lifecycle_rules = [
    {
      name    = "expire-old-logs"
      enabled = true
      filter = {
        prefix_match = ["logs/"]
      }
      actions = {
        base_blob = {
          delete_after_days = 90
        }
      }
    },
    {
      name    = "archive-old-data"
      enabled = true
      filter = {
        prefix_match = ["archive/"]
      }
      actions = {
        base_blob = {
          tier_to_cool_after_days    = 30
          tier_to_archive_after_days = 90
        }
      }
    },
    {
      name    = "cleanup-old-versions"
      enabled = true
      actions = {
        version = {
          delete_after_days = 30
        }
      }
    }
  ]

  tags = {
    Purpose = "logs"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Resource group name | `string` | n/a | yes |
| `location` | Azure region | `string` | n/a | yes |
| `storage_account_name` | Globally unique storage account name | `string` | n/a | yes |
| `account_tier` | Account tier (`Standard` or `Premium`) | `string` | `"Standard"` | no |
| `account_replication_type` | Replication type | `string` | `"LRS"` | no |
| `account_kind` | Storage account kind | `string` | `"StorageV2"` | no |
| `access_tier` | Default blob access tier | `string` | `"Hot"` | no |
| `versioning_enabled` | Enable blob versioning | `bool` | `false` | no |
| `change_feed_enabled` | Enable blob change feed | `bool` | `false` | no |
| `blob_delete_retention_days` | Blob soft-delete retention days | `number` | `7` | no |
| `container_delete_retention_days` | Container soft-delete retention days | `number` | `7` | no |
| `infrastructure_encryption_enabled` | Enable infrastructure encryption | `bool` | `true` | no |
| `https_traffic_only_enabled` | Require HTTPS | `bool` | `true` | no |
| `min_tls_version` | Minimum TLS version | `string` | `"TLS1_2"` | no |
| `allow_nested_items_to_be_public` | Allow anonymous public blob access | `bool` | `false` | no |
| `shared_access_key_enabled` | Allow shared key authorization | `bool` | `true` | no |
| `containers` | Blob containers to create | `map(object)` | `{}` | no |
| `network_rules` | Network access rules. Set to `null` to allow all networks | `object` | `null` | no |
| `lifecycle_rules` | Blob lifecycle management rules | `list(object)` | `[]` | no |
| `customer_managed_key` | Customer-managed key encryption config | `object` | `null` | no |
| `tags` | Tags applied to the storage account | `map(string)` | `{}` | no |

### `containers` object

```hcl
containers = {
  uploads = {
    access_type = optional(string, "private")
    metadata    = optional(map(string))
  }
}
```

Supported `access_type` values: `private`, `blob`, `container`.

### `network_rules` object

```hcl
network_rules = {
  default_action             = optional(string, "Deny")
  bypass                     = optional(list(string), ["AzureServices"])
  ip_rules                   = optional(list(string), [])
  virtual_network_subnet_ids = optional(list(string), [])
  private_link_access = optional(list(object({
    endpoint_resource_id = string
    endpoint_tenant_id   = optional(string)
  })), [])
}
```

### `lifecycle_rules` object

```hcl
lifecycle_rules = [
  {
    name    = string
    enabled = optional(bool, true)
    filter = optional(object({
      prefix_match = optional(list(string))
      blob_types   = optional(list(string), ["blockBlob"])
      tags = optional(list(object({
        name  = string
        op    = string
        value = string
      })), [])
    }))
    actions = {
      base_blob = optional(object({
        tier_to_cool_after_days    = optional(number)
        tier_to_archive_after_days = optional(number)
        delete_after_days          = optional(number)
      }))
      version = optional(object({
        delete_after_days = optional(number)
      }))
      snapshot = optional(object({
        delete_after_days = optional(number)
      }))
    }
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| `storage_account_id` | ID of the storage account |
| `storage_account_name` | Name of the storage account |
| `primary_blob_endpoint` | Primary blob endpoint URL |
| `primary_blob_host` | Primary blob host name |
| `primary_access_key` | Primary access key (sensitive, null when shared keys disabled) |
| `container_names` | Names of created blob containers |
| `network_rules_enabled` | Whether network rules are configured |
| `versioning_enabled` | Whether blob versioning is enabled |
| `customer_managed_key_enabled` | Whether CMK encryption is enabled |

## Security defaults

This module applies secure defaults suitable for private application storage:

- Anonymous public access blocked (`allow_nested_items_to_be_public = false`)
- HTTPS required (`https_traffic_only_enabled = true`)
- Minimum TLS 1.2
- Infrastructure encryption enabled by default
- Blob and container soft-delete retention enabled (7 days)
- Network rules optional; when set, default action is `Deny`

## Validation rules

- `storage_account_name` must be 3-24 lowercase alphanumeric characters
- `account_tier` must be `Standard` or `Premium`
- `account_replication_type` must be one of `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS`, `RAGZRS`
- `customer_managed_key.key_vault_key_id` is required when `customer_managed_key` is set
- Soft-delete retention values must be between 1 and 365 days

## What this module does not manage

- Azure Files shares, queues, or tables
- Static website hosting
- Event Grid notifications
- Object replication rules
- Private endpoints (configure separately in a networking module)
