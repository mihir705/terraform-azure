resource "random_password" "admin" {
  count = var.administrator_password == null ? 1 : 0

  length           = var.generate_password.length
  special          = var.generate_password.special
  override_special = var.generate_password.override_special
}

locals {
  administrator_password = coalesce(
    var.administrator_password,
    random_password.admin[0].result
  )

  private_dns_zone_id = coalesce(
    var.private_dns_zone_id,
    try(azurerm_private_dns_zone.this[0].id, null)
  )
}

check "password_source_required" {
  assert {
    condition     = var.administrator_password != null || var.generate_password != null
    error_message = "Provide administrator_password or generate_password."
  }
}

check "private_dns_zone_name_required" {
  assert {
    condition     = !var.create_private_dns_zone || var.private_dns_zone_name != null
    error_message = "private_dns_zone_name is required when create_private_dns_zone is true."
  }
}

check "vnet_integration_recommended" {
  assert {
    condition     = var.public_network_access_enabled || var.delegated_subnet_id != null
    error_message = "delegated_subnet_id is required when public_network_access_enabled is false."
  }
}

resource "azurerm_private_dns_zone" "this" {
  count = var.create_private_dns_zone && var.private_dns_zone_id == null ? 1 : 0

  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    Name = var.private_dns_zone_name
  })
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgres_version
  sku_name                      = var.sku_name
  administrator_login           = var.administrator_login
  administrator_password        = local.administrator_password
  zone                          = var.zone
  public_network_access_enabled = var.public_network_access_enabled

  storage_mb        = var.storage_mb
  storage_tier      = var.storage_tier
  auto_grow_enabled = var.auto_grow_enabled

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = local.private_dns_zone_id

  dynamic "high_availability" {
    for_each = var.high_availability != null ? [var.high_availability] : []

    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = try(high_availability.value.standby_availability_zone, null)
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []

    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = try(maintenance_window.value.start_minute, 0)
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    ignore_changes = [
      administrator_password,
      zone,
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each = var.databases

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = each.value.charset
  collation = each.value.collation
}

resource "azurerm_postgresql_flexible_server_configuration" "this" {
  for_each = var.configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = each.value.value
}

check "virtual_network_id_for_dns_link" {
  assert {
    condition     = !var.create_private_dns_zone || var.virtual_network_id != null || var.private_dns_zone_id != null
    error_message = "virtual_network_id is required when create_private_dns_zone is true."
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count = var.create_private_dns_zone && var.private_dns_zone_id == null && var.virtual_network_id != null ? 1 : 0

  name                  = "${var.name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = var.virtual_network_id

  tags = var.tags
}
