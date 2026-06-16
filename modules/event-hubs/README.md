# Event Hubs Module

Terraform module to create an Azure Event Hubs namespace with a Kafka-compatible event hub and optional consumer groups. Mirrors the AWS MSK pattern for streaming workloads.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_eventhub_namespace` | Yes | Event Hubs namespace |
| `azurerm_eventhub` | Yes | Event hub (Kafka protocol on Standard/Premium) |
| `azurerm_eventhub_consumer_group` | No | One per entry in `consumer_groups` |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |

## Usage

```hcl
event_hubs_namespaces = {
  app-events = {
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    namespace_name      = "my-company-events-prod"
    sku                 = "Standard"
    event_hub_name      = "app-events"
    partition_count     = 4

    consumer_groups = {
      analytics = {}
      processor = {}
    }

    tags = { Purpose = "app-events" }
  }
}
```

Kafka clients connect to:

```
<namespace_name>.servicebus.windows.net:9093
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `namespace_name` | Namespace name | `string` | — | yes |
| `sku` | Basic, Standard, Premium | `string` | `Standard` | no |
| `event_hub_name` | Event hub name | `string` | `null` | no* |
| `event_hub_name_prefix` | Event hub prefix | `string` | `null` | no* |
| `partition_count` | Partition count | `number` | `2` | no |
| `consumer_groups` | Consumer groups map | `map(object)` | `{}` | no |
| `capture_description` | Archive capture config | `object` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

\* Exactly one of `event_hub_name` or `event_hub_name_prefix` is required.

## Outputs

| Name | Description |
|------|-------------|
| `kafka_bootstrap_servers` | Kafka bootstrap endpoint |
| `kafka_enabled` | Whether SKU supports Kafka |
| `event_hub_name` | Event hub name |
| `consumer_group_names` | Consumer groups by logical key |

## Notes

- Kafka protocol requires **Standard** or **Premium** SKU.
- Authentication uses SASL/SSL with connection strings or Azure AD — configure separately.
- For full MSK parity (broker-level tuning), add Kafka configuration via Azure Portal or `azurerm_eventhub_namespace` policy resources.
