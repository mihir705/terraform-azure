# Service Bus Queue Module

Terraform module to create an Azure Service Bus namespace and queue with dead-letter configuration. Mirrors the AWS SQS queue pattern. Reuse an existing namespace from the service-bus-topic module via `existing_namespace_name`.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_servicebus_queue` | Yes | Point-to-point queue |
| `azurerm_servicebus_namespace` | No | When `create_namespace = true` |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example).

```hcl
service_bus_queues = {
  order-processor = {
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    create_namespace    = false
    existing_namespace_name = "my-company-sb-prod"
    name                = "order-processor"
    create_dlq          = true
    max_delivery_count  = 5
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Queue name | `string` | `null` | no* |
| `name_prefix` | Queue name prefix | `string` | `null` | no* |
| `create_namespace` | Create namespace | `bool` | `true` | no |
| `existing_namespace_name` | Existing namespace | `string` | `null` | no |
| `create_dlq` | Enable dead-letter via max delivery | `bool` | `true` | no |
| `max_delivery_count` | Max receives before DLQ | `number` | `10` | no |
| `lock_duration` | Message lock duration | `string` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

\* Exactly one of `name` or `name_prefix` is required.

## Outputs

| Name | Description |
|------|-------------|
| `queue_id` | Queue ID |
| `queue_name` | Queue name |
| `namespace_name` | Namespace name |
| `dead_letter_enabled` | Whether DLQ behavior is configured |

## Notes

- Service Bus uses a built-in dead-letter sub-queue; no separate DLQ resource is required.
- Set `create_namespace = false` and `existing_namespace_name` to share a namespace with topics.
