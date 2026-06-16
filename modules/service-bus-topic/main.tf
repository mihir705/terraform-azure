data "azurerm_servicebus_namespace" "existing" {
  count = var.create_namespace ? 0 : 1

  name                = var.existing_namespace_name
  resource_group_name = coalesce(var.existing_namespace_resource_group_name, var.resource_group_name)
}

locals {
  namespace_id   = var.create_namespace ? azurerm_servicebus_namespace.namespace[0].id : data.azurerm_servicebus_namespace.existing[0].id
  namespace_name = var.create_namespace ? azurerm_servicebus_namespace.namespace[0].name : data.azurerm_servicebus_namespace.existing[0].name

  topic_name_tag = (
    var.name != null ? var.name :
    var.name_prefix != null ? "${var.name_prefix}-topic" :
    "servicebus-topic"
  )
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
    condition     = var.create_namespace || (var.existing_namespace_name != null && var.existing_namespace_name != "")
    error_message = "existing_namespace_name is required when create_namespace is false."
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

resource "azurerm_servicebus_topic" "topic" {
  name         = coalesce(var.name, try("${var.name_prefix}-topic", null))
  namespace_id = local.namespace_id

  enable_partitioning                     = var.enable_partitioning
  enable_express                          = var.enable_express
  max_size_in_megabytes                   = var.max_size_in_megabytes
  default_message_ttl                     = var.default_message_ttl
  duplicate_detection_history_time_window = var.duplicate_detection_history_time_window
  requires_duplicate_detection            = var.requires_duplicate_detection
  support_ordering                        = var.support_ordering
}

resource "azurerm_servicebus_subscription" "subscription" {
  for_each = var.subscriptions

  name               = each.key
  topic_id           = azurerm_servicebus_topic.topic.id
  max_delivery_count = each.value.max_delivery_count

  default_message_ttl                       = try(each.value.default_message_ttl, null)
  lock_duration                             = try(each.value.lock_duration, null)
  requires_session                          = each.value.requires_session
  dead_lettering_on_message_expiration      = each.value.dead_lettering_on_message_expiration
  dead_lettering_on_filter_evaluation_error = each.value.dead_lettering_on_filter_evaluation_error
  auto_delete_on_idle                       = try(each.value.auto_delete_on_idle, null)
  forward_to                                = try(each.value.forward_to, null)
  forward_dead_lettered_messages_to         = try(each.value.forward_dead_lettered_messages_to, null)
}

resource "azurerm_servicebus_subscription_rule" "sql_filter" {
  for_each = {
    for key, subscription in var.subscriptions :
    key => subscription
    if try(subscription.sql_filter, null) != null
  }

  name            = "${each.key}-sql"
  subscription_id = azurerm_servicebus_subscription.subscription[each.key].id
  filter_type     = "SqlFilter"
  sql_filter      = each.value.sql_filter
}

resource "azurerm_servicebus_subscription_rule" "correlation_filter" {
  for_each = {
    for key, subscription in var.subscriptions :
    key => subscription
    if try(subscription.correlation_filter, null) != null
  }

  name            = "${each.key}-correlation"
  subscription_id = azurerm_servicebus_subscription.subscription[each.key].id
  filter_type     = "CorrelationFilter"

  dynamic "correlation_filter" {
    for_each = [each.value.correlation_filter]

    content {
      correlation_id      = try(correlation_filter.value.correlation_id, null)
      message_id          = try(correlation_filter.value.message_id, null)
      to                  = try(correlation_filter.value.to, null)
      reply_to            = try(correlation_filter.value.reply_to, null)
      label               = try(correlation_filter.value.label, null)
      session_id          = try(correlation_filter.value.session_id, null)
      reply_to_session_id = try(correlation_filter.value.reply_to_session_id, null)
      content_type        = try(correlation_filter.value.content_type, null)
    }
  }
}
