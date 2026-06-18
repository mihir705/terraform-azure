data "azurerm_servicebus_namespace" "existing" {
  count = var.create_namespace || var.existing_namespace_id != null ? 0 : 1

  name                = var.existing_namespace_name
  resource_group_name = coalesce(var.existing_namespace_resource_group_name, var.resource_group_name)
}

locals {
  namespace_id = var.create_namespace ? azurerm_servicebus_namespace.namespace[0].id : (
    var.existing_namespace_id != null ? var.existing_namespace_id : data.azurerm_servicebus_namespace.existing[0].id
  )
  namespace_name = var.create_namespace ? azurerm_servicebus_namespace.namespace[0].name : coalesce(
    var.existing_namespace_name,
    try(data.azurerm_servicebus_namespace.existing[0].name, null)
  )

  queue_name_tag = (
    var.name != null ? var.name :
    var.name_prefix != null ? "${var.name_prefix}-queue" :
    "servicebus-queue"
  )

  effective_max_delivery_count = var.create_dlq ? var.max_delivery_count : 2147483647
}

check "name_exclusive" {
  assert {
    condition     = (var.name != null) != (var.name_prefix != null)
    error_message = "Exactly one of name or name_prefix must be set."
  }
}

check "namespace_name_required" {
  assert {
    condition     = !var.create_namespace || (var.namespace_name != null && var.namespace_name != "")
    error_message = "namespace_name is required when create_namespace is true."
  }
}

check "existing_namespace_required" {
  assert {
    condition     = var.create_namespace || var.existing_namespace_id != null || (var.existing_namespace_name != null && var.existing_namespace_name != "")
    error_message = "existing_namespace_id or existing_namespace_name is required when create_namespace is false."
  }
}

check "max_delivery_count_range" {
  assert {
    condition     = var.max_delivery_count >= 1 && var.max_delivery_count <= 2147483647
    error_message = "max_delivery_count must be between 1 and 2147483647."
  }
}

check "partitioning_sku" {
  assert {
    condition     = !var.enable_partitioning || var.namespace_sku != "Basic"
    error_message = "enable_partitioning requires Standard or Premium namespace SKU."
  }
}

resource "azurerm_servicebus_namespace" "namespace" {
  count = var.create_namespace ? 1 : 0

  name                = var.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.namespace_sku
  capacity            = var.namespace_sku == "Premium" ? var.namespace_capacity : null

  tags = merge(var.tags, {
    Name = var.namespace_name
  })
}

resource "azurerm_servicebus_queue" "queue" {
  name         = coalesce(var.name, try("${var.name_prefix}-queue", null))
  namespace_id = local.namespace_id

  enable_partitioning                     = var.enable_partitioning
  enable_express                          = var.enable_express
  max_size_in_megabytes                   = var.max_size_in_megabytes
  default_message_ttl                     = var.default_message_ttl
  lock_duration                           = var.lock_duration
  max_delivery_count                      = local.effective_max_delivery_count
  requires_session                        = var.requires_session
  requires_duplicate_detection            = var.requires_duplicate_detection
  duplicate_detection_history_time_window = var.duplicate_detection_history_time_window
  dead_lettering_on_message_expiration    = var.dead_lettering_on_message_expiration
  forward_to                              = var.forward_to
  forward_dead_lettered_messages_to       = var.forward_dead_lettered_messages_to
}
