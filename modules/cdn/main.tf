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
  origin_group_name           = "${var.endpoint_name}-origin-group"
  route_name                  = "${var.endpoint_name}-route"
  health_probe_path           = var.origin_path != "" ? var.origin_path : "/"
  route_patterns              = var.origin_path != "" ? ["${var.origin_path}/*"] : ["/*"]
  supported_protocols         = var.is_http_allowed && var.is_https_allowed ? ["Http", "Https"] : var.is_https_allowed ? ["Https"] : ["Http"]

  query_string_caching_behavior = (
    var.querystring_caching_behaviour == "UseQueryString" ? "UseQueryString" :
    var.querystring_caching_behaviour == "BypassCaching" ? "IgnoreQueryString" :
    "IgnoreQueryString"
  )
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

resource "azurerm_cdn_frontdoor_profile" "profile" {
  name                = var.name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = var.endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id

  tags = merge(var.tags, {
    Name = var.endpoint_name
  })
}

resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  name                     = local.origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = local.health_probe_path
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  name                          = "storage-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = local.origin_host_name
  origin_host_header             = local.origin_host_header
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000

  dynamic "private_link" {
    for_each = var.sku_name == "Premium_AzureFrontDoor" && var.enable_origin_private_link ? [1] : []

    content {
      request_message        = "Azure Front Door private link to storage blob origin"
      target_type            = "blob"
      location               = var.location
      private_link_target_id = local.origin_storage_account_id
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = local.route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.origin.id]

  supported_protocols    = local.supported_protocols
  patterns_to_match      = local.route_patterns
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = var.is_https_allowed

  cache {
    query_string_caching_behavior = local.query_string_caching_behavior
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  for_each = var.custom_domains

  name                     = replace(each.key, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
  host_name                = each.value.host_name

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}
