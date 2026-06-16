# Service Bus Topic Module

Terraform module to create an Azure Service Bus namespace and topic with optional subscriptions and filters. Mirrors the AWS SNS topic pattern.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_servicebus_topic` | Yes | Pub/sub topic |
| `azurerm_servicebus_namespace` | No | When `create_namespace = true` |
| `azurerm_servicebus_subscription` | No | One per entry in `subscriptions` |
| `azurerm_servicebus_subscription_rule` | No | SQL or correlation filters |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples.

### Topic with email-style fan-out subscriptions

```hcl
service_bus_topics = {
  app-alerts = {
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    namespace_name      = "my-company-sb-prod"
    name                = "app-alerts"

    subscriptions = {
      processor = {
        max_delivery_count = 10
      }
    }

    tags = { Purpose = "app-alerts" }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `create_namespace` | Create namespace | `bool` | `true` | no |
| `namespace_name` | Namespace name | `string` | `null` | no* |
| `existing_namespace_name` | Existing namespace | `string` | `null` | no* |
| `name` | Topic name | `string` | `null` | no** |
| `name_prefix` | Topic name prefix | `string` | `null` | no** |
| `subscriptions` | Subscriptions map | `map(object)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

\* Provide `namespace_name` when creating, or `existing_namespace_name` when reusing.  
\** Exactly one of `name` or `name_prefix` is required.

## Outputs

| Name | Description |
|------|-------------|
| `namespace_id` | Namespace ID |
| `namespace_name` | Namespace name |
| `topic_id` | Topic ID |
| `topic_name` | Topic name |
| `subscription_ids` | Subscription IDs by logical key |

## Validation

- Exclusive `name` / `name_prefix`
- Namespace name requirements
- Partitioning requires Standard/Premium SKU

## Coverage matrix

| Capability | Supported | Notes |
|------------|-----------|-------|
| Topics | Yes | Standard pub/sub |
| Subscriptions | Yes | With filters |
| SQL filters | Yes | `sql_filter` on subscription |
| Correlation filters | Yes | `correlation_filter` object |
| Dead-letter forwarding | Yes | `forward_dead_lettered_messages_to` |
| Existing namespace | Yes | Share namespace with queue module |
| FIFO | No | Use sessions + ordering instead |
| Email/SMS protocols | No | Use Logic Apps or Functions |

## Environment wiring

| Key | Resolves to |
|-----|-------------|
| `namespace_key` | Shared namespace from another topic module |

## Notes

- Basic SKU does not support topics; use Standard or Premium.
- Reuse `existing_namespace_name` to share a namespace with the service-bus-queue module.
