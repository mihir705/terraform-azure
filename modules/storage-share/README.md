# Storage Share Module

Terraform module to create an Azure Files share with optional storage account creation. Mirrors the AWS EFS shared file system pattern for SMB/NFS mounts.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_storage_share` | Yes | Azure Files share |
| `azurerm_storage_account` | No | When `create_storage_account = true` |
| `azurerm_storage_share_directory` | No | One per entry in `directories` |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

```hcl
storage_shares = {
  app-data = {
    resource_group_name  = "my-company-rg-prod"
    location             = "eastus"
    storage_account_name = "mycompanyfilesprod"
    name                 = "app-data"
    quota_gb             = 512
  }
}
```

Mount from a VM:

```bash
sudo mount -t cifs //mycompanyfilesprod.file.core.windows.net/app-data /mnt/app-data \
  -o vers=3.0,username=mycompanyfilesprod,password=<storage-key>,dir_mode=0777,file_mode=0777
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Share name | `string` | — | yes |
| `quota_gb` | Share quota in GB | `number` | `100` | no |
| `access_tier` | Share access tier | `string` | `TransactionOptimized` | no |
| `enabled_protocol` | SMB or NFS | `string` | `SMB` | no |
| `directories` | Subdirectories to create | `map(string)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `share_name` | Share name |
| `share_url` | UNC share URL |
| `mount_path` | Suggested Linux mount path |
| `storage_account_name` | Storage account name |

## Notes

- For production NFS/SMB at scale, consider Azure NetApp Files for EFS-like performance.
- Private endpoints and network rules should be configured on the storage account separately.
