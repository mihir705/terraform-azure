data "azurerm_storage_account" "existing_origin" {
  count = var.create_origin_storage_account ? 0 : 1

  name                = var.existing_origin_storage_account_name
  resource_group_name = coalesce(var.existing_origin_storage_account_resource_group_name, var.resource_group_name)
}

locals {
  origin_storage_account_id   = var.create_origin_storage_account ? azurerm_storage_account.origin[0].id : data.azurerm_storage_account.existing_origin[0].id
  origin_storage_account_name = var.create_origin_storage_account ? azurerm_storage_account.origin[0].name : data.azurerm_storage_account.existing_origin[0].name
  origin_blob_host            = var.create_origin_storage_account ? azurerm_storage_account.origin[0].primary_blob_host : data.azurerm_storage_account.existing_origin[0].primary_blob_host
  origin_host_name            = coalesce(var.origin_host_name, local.origin_blob_host)
  origin_host_header          = coalesce(var.origin_host_header, local.origin_host_name)
}

check "origin_storage_account_name_required" {
  assert {
    condition     = !var.create_origin_storage_account || (var.origin_storage_account_name != null && var.origin_storage_account_name != "")
    error_message = "origin_storage_account_name is required when create_origin_storage_account is true."
  }
}

check "existing_origin_storage_account_required" {
  assert {
    condition     = var.create_origin_storage_account || (var.existing_origin_storage_account_name != null && var.existing_origin_storage_account_name != "")
    error_message = "existing_origin_storage_account_name is required when create_origin_storage_account is false."
  }
}

check "https_or_http_required" {
  assert {
    condition     = var.is_http_allowed || var.is_https_allowed
    error_message = "At least one of is_http_allowed or is_https_allowed must be true."
  }
}

resource "azurerm_storage_account" "origin" {
  count = var.create_origin_storage_account ? 1 : 0

  name                     = var.origin_storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.origin_storage_account_tier
  account_replication_type = var.origin_storage_replication_type
  account_kind             = "StorageV2"

  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_cdn_profile" "profile" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku_name

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "azurerm_cdn_endpoint" "endpoint" {
  name                = var.endpoint_name
  profile_name        = azurerm_cdn_profile.profile.name
  location            = var.location
  resource_group_name = var.resource_group_name

  is_http_allowed  = var.is_http_allowed
  is_https_allowed = var.is_https_allowed

  origin_host_header            = local.origin_host_header
  origin_path                   = var.origin_path != "" ? var.origin_path : null
  querystring_caching_behaviour = var.querystring_caching_behaviour
  optimization_type             = var.optimization_type

  origin {
    name      = "storage-origin"
    host_name = local.origin_host_name
  }

  dynamic "geo_filter" {
    for_each = var.geo_filter != null ? [var.geo_filter] : []

    content {
      relative_path = geo_filter.value.relative_path
      action        = geo_filter.value.action
      country_codes = geo_filter.value.country_codes
    }
  }

  tags = merge(var.tags, {
    Name = var.endpoint_name
  })
}

resource "azurerm_cdn_endpoint_custom_domain" "custom_domain" {
  for_each = var.custom_domains

  name            = each.key
  cdn_endpoint_id = azurerm_cdn_endpoint.endpoint.id
  host_name       = each.value.host_name
}
