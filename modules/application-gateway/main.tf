locals {
  sku_name = var.enable_waf ? "WAF_v2" : "Standard_v2"
  sku_tier = var.enable_waf ? "WAF_v2" : "Standard_v2"

  listener_rules = {
    for item in flatten([
      for listener_key, listener in var.listeners : [
        for rule in try(listener.rules, []) : {
          key          = "${listener_key}-${rule.name}"
          listener_key = listener_key
          rule         = rule
        }
      ]
    ]) : item.key => item
  }

  backend_address_pools = {
    for tg_key, tg in var.target_groups : tg_key => [
      for target in try(tg.targets, []) :
      coalesce(try(target.ip_address, null), try(target.fqdn, null))
    ]
  }

  # optional(bool, false) on target_groups makes an unset flag read as false, not null.
  probe_pick_host = {
    for tg_key, tg in var.target_groups :
    tg_key => try(tg.host_name, null) == null
    if try(tg.health_check_enabled, true)
  }

  backend_pick_host_from_address = {
    for tg_key, tg in var.target_groups :
    tg_key => try(tg.host_name, null) == null && length([
      for target in try(tg.targets, []) : target if try(target.ip_address, null) != null
    ]) > 0
  }
}

check "target_groups_required" {
  assert {
    condition     = length(var.target_groups) > 0
    error_message = "At least one target group is required."
  }
}

check "listeners_required" {
  assert {
    condition     = length(var.listeners) > 0
    error_message = "At least one listener is required."
  }
}

check "listener_forward_target_groups" {
  assert {
    condition = alltrue(flatten([
      for listener in var.listeners : concat(
        listener.default_action.type == "forward" ? [
          contains(keys(var.target_groups), try(listener.default_action.target_group_key, ""))
        ] : [true],
        [
          for rule in try(listener.rules, []) :
          rule.action.type != "forward" || contains(keys(var.target_groups), try(rule.action.target_group_key, ""))
        ]
      )
    ]))
    error_message = "Forward actions must reference a valid target_group_key."
  }
}

resource "azurerm_public_ip" "gateway" {
  count = !var.internal && var.public_ip_address_id == null ? 1 : 0

  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.public_ip_zones

  tags = merge(var.tags, {
    Name = "${var.name}-pip"
  })
}

resource "azurerm_application_gateway" "gateway" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_http2        = var.enable_http2

  sku {
    name     = local.sku_name
    tier     = local.sku_tier
    capacity = var.capacity
  }

  dynamic "waf_configuration" {
    for_each = var.enable_waf ? [1] : []

    content {
      enabled          = true
      firewall_mode    = var.waf_mode
      rule_set_type    = "OWASP"
      rule_set_version = "3.2"
    }
  }

  dynamic "ssl_policy" {
    for_each = var.ssl_policy_type == "Predefined" ? [1] : []

    content {
      policy_type = "Predefined"
      policy_name = var.ssl_policy_name
    }
  }

  dynamic "ssl_policy" {
    for_each = var.ssl_policy_type == "Custom" ? [1] : []

    content {
      policy_type          = "Custom"
      min_protocol_version = var.ssl_policy_min_protocol_version
      cipher_suites        = var.ssl_policy_cipher_suites
    }
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.internal ? [1] : []

    content {
      name                          = "frontend-ip-private"
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = var.subnet_id
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = !var.internal ? [1] : []

    content {
      name                 = "frontend-ip-public"
      public_ip_address_id = coalesce(var.public_ip_address_id, try(azurerm_public_ip.gateway[0].id, null))
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.target_groups

    content {
      name         = backend_address_pool.key
      ip_addresses = [for addr in local.backend_address_pools[backend_address_pool.key] : addr if can(regex("^\\d", addr))]
      fqdns        = [for addr in local.backend_address_pools[backend_address_pool.key] : addr if !can(regex("^\\d", addr))]
    }
  }

  dynamic "probe" {
    for_each = {
      for tg_key, tg in var.target_groups :
      tg_key => tg
      if try(tg.health_check_enabled, true)
    }

    content {
      name                                      = "${probe.key}-probe"
      protocol                                  = contains(["HTTPS", "Https"], try(probe.value.health_check_protocol, "Http")) ? "Https" : "Http"
      path                                      = try(probe.value.health_check_path, "/")
      interval                                  = try(probe.value.health_check_interval, 30)
      timeout                                   = try(probe.value.health_check_timeout, 30)
      unhealthy_threshold                       = try(probe.value.health_check_unhealthy_threshold, 3)
      pick_host_name_from_backend_http_settings = local.probe_pick_host[probe.key] ? coalesce(
        try(probe.value.pick_host_name_from_backend_http_settings, null),
        true
      ) : false
      host = local.probe_pick_host[probe.key] ? null : probe.value.host_name
      port                                      = try(probe.value.health_check_port, probe.value.port)
      match {
        status_code = [try(probe.value.health_check_matcher, "200-399")]
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.target_groups

    content {
      name                                = "${backend_http_settings.key}-http-settings"
      cookie_based_affinity               = try(backend_http_settings.value.cookie_based_affinity, "Disabled")
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = 30
      probe_name                          = try(backend_http_settings.value.health_check_enabled, true) ? "${backend_http_settings.key}-probe" : null
      pick_host_name_from_backend_address = local.backend_pick_host_from_address[backend_http_settings.key] ? coalesce(
        try(backend_http_settings.value.pick_host_name_from_backend_address, null),
        true
      ) : false
      host_name = try(backend_http_settings.value.host_name, null)

      dynamic "connection_draining" {
        for_each = try(backend_http_settings.value.connection_draining_enabled, false) ? [1] : []

        content {
          enabled           = true
          drain_timeout_sec = try(backend_http_settings.value.connection_draining_timeout_sec, 30)
        }
      }
    }
  }

  dynamic "ssl_certificate" {
    for_each = {
      for listener_key, listener in var.listeners :
      listener_key => listener
      if contains(["HTTPS", "Https"], listener.protocol) && try(listener.key_vault_secret_id, null) != null
    }

    content {
      name                = coalesce(try(ssl_certificate.value.certificate_name, null), "${ssl_certificate.key}-cert")
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "http_listener" {
    for_each = var.listeners

    content {
      name                           = http_listener.key
      frontend_ip_configuration_name = var.internal ? "frontend-ip-private" : "frontend-ip-public"
      frontend_port_name             = "${http_listener.key}-port"
      protocol                       = contains(["HTTPS", "Https"], http_listener.value.protocol) ? "Https" : "Http"
      ssl_certificate_name           = contains(["HTTPS", "Https"], http_listener.value.protocol) ? coalesce(try(http_listener.value.certificate_name, null), "${http_listener.key}-cert") : null
    }
  }

  dynamic "frontend_port" {
    for_each = var.listeners

    content {
      name = "${frontend_port.key}-port"
      port = frontend_port.value.port
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.listeners

    content {
      name                        = "${request_routing_rule.key}-default"
      rule_type                   = "Basic"
      http_listener_name          = request_routing_rule.key
      priority                    = 100
      backend_address_pool_name   = request_routing_rule.value.default_action.type == "forward" ? request_routing_rule.value.default_action.target_group_key : null
      backend_http_settings_name  = request_routing_rule.value.default_action.type == "forward" ? "${request_routing_rule.value.default_action.target_group_key}-http-settings" : null
      redirect_configuration_name = request_routing_rule.value.default_action.type == "redirect" ? "${request_routing_rule.key}-redirect" : null
    }
  }

  dynamic "redirect_configuration" {
    for_each = {
      for listener_key, listener in var.listeners :
      listener_key => listener
      if listener.default_action.type == "redirect"
    }

    content {
      name                 = "${redirect_configuration.key}-redirect"
      redirect_type        = redirect_configuration.value.default_action.redirect.redirect_type
      target_url           = try(redirect_configuration.value.default_action.redirect.target_url, null)
      include_path         = try(redirect_configuration.value.default_action.redirect.include_path, true)
      include_query_string = try(redirect_configuration.value.default_action.redirect.include_query_string, true)
    }
  }

  dynamic "url_path_map" {
    for_each = {
      for listener_key, listener in var.listeners :
      listener_key => listener
      if length(try(listener.rules, [])) > 0
    }

    content {
      name                               = "${url_path_map.key}-path-map"
      default_backend_address_pool_name  = url_path_map.value.default_action.type == "forward" ? url_path_map.value.default_action.target_group_key : null
      default_backend_http_settings_name = url_path_map.value.default_action.type == "forward" ? "${url_path_map.value.default_action.target_group_key}-http-settings" : null

      dynamic "path_rule" {
        for_each = try(url_path_map.value.rules, [])

        content {
          name                       = path_rule.value.name
          paths                      = coalesce(try(path_rule.value.path_pattern, null), ["/*"])
          backend_address_pool_name  = path_rule.value.action.type == "forward" ? path_rule.value.action.target_group_key : null
          backend_http_settings_name = path_rule.value.action.type == "forward" ? "${path_rule.value.action.target_group_key}-http-settings" : null
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}
