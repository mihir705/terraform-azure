# Storage Queue Module

Terraform module to create an Azure Storage Queue — a simple alternative to Service Bus queues. Mirrors a lightweight AWS SQS pattern using cloud-native storage queues.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_storage_queue` | Yes | Storage account queue |
| `azurerm_storage_account` | No | When `create_storage_account = true` |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples.

```hcl
storage_queues = {
  background-jobs = {
    resource_group_name  = "my-company-rg-prod"
    location             = "eastus"
    storage_account_name = "mycompanyqueuesprod"
    name                 = "background-jobs"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Queue name | `string` | `null` | no* |
| `name_prefix` | Queue name prefix | `string` | `null` | no* |
| `create_storage_account` | Create storage account | `bool` | `true` | no |
| `metadata` | Queue metadata | `map(string)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

\* Exactly one of `name` or `name_prefix` is required.

## Outputs

| Name | Description |
|------|-------------|
| `queue_name` | Queue name |
| `queue_url` | Queue URL |
| `storage_account_name` | Storage account name |

## Notes

- Storage queues are best for simple workloads; use Service Bus for advanced messaging features.
- No native dead-letter queue; implement poison-message handling in application code.
