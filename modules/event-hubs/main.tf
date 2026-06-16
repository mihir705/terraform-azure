locals {
  event_hub_name_tag = (
    var.event_hub_name != null ? var.event_hub_name :
    var.event_hub_name_prefix != null ? "${var.event_hub_name_prefix}-hub" :
    "event-hub"
  )

  kafka_enabled = var.sku != "Basic"
}

check "event_hub_name_exclusive" {
  assert {
    condition     = var.event_hub_name == null || var.event_hub_name_prefix == null
    error_message = "Set only one of event_hub_name or event_hub_name_prefix."
  }
}

check "auto_inflate_standard_only" {
  assert {
    condition     = !var.auto_inflate_enabled || var.sku == "Standard"
    error_message = "auto_inflate_enabled is only supported for Standard SKU namespaces."
  }
}

check "maximum_throughput_units_required" {
  assert {
    condition     = !var.auto_inflate_enabled || var.maximum_throughput_units != null
    error_message = "maximum_throughput_units is required when auto_inflate_enabled is true."
  }
}

check "capture_encoding" {
  assert {
    condition = var.capture_description == null || contains(
      ["Avro", "AvroDeflate"],
      var.capture_description.encoding
    )
    error_message = "capture encoding must be Avro or AvroDeflate."
  }
}

resource "azurerm_eventhub_namespace" "namespace" {
  name                = var.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity

  auto_inflate_enabled     = var.sku == "Standard" ? var.auto_inflate_enabled : null
  maximum_throughput_units = var.auto_inflate_enabled ? var.maximum_throughput_units : null
  zone_redundant           = var.zone_redundant
  minimum_tls_version      = var.minimum_tls_version

  tags = merge(var.tags, {
    Name = var.namespace_name
  })
}

resource "azurerm_eventhub" "hub" {
  name                = coalesce(var.event_hub_name, local.event_hub_name_tag)
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  resource_group_name = var.resource_group_name
  partition_count     = var.partition_count
  message_retention   = var.message_retention

  dynamic "capture_description" {
    for_each = var.capture_description != null ? [var.capture_description] : []

    content {
      enabled             = capture_description.value.enabled
      encoding            = capture_description.value.encoding
      interval_in_seconds = capture_description.value.interval_in_seconds
      size_limit_in_bytes = capture_description.value.size_limit_in_bytes

      destination {
        name                = capture_description.value.destination.name
        archive_name_format = capture_description.value.destination.archive_name_format
        blob_container_name = capture_description.value.destination.blob_container_name
        storage_account_id  = capture_description.value.destination.storage_account_id
      }
    }
  }
}

resource "azurerm_eventhub_consumer_group" "consumer_group" {
  for_each = var.consumer_groups

  name                = coalesce(try(each.value.name, null), each.key)
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  eventhub_name       = azurerm_eventhub.hub.name
  resource_group_name = var.resource_group_name
}
