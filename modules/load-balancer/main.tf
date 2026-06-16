locals {
  frontend_subnet_id = coalesce(var.frontend_subnet_id, try(var.subnet_ids[0], null))

  target_attachments = {
    for item in flatten([
      for tg_key, tg in var.target_groups : [
        for idx, target in try(tg.targets, []) : {
          key    = "${tg_key}-${idx}"
          tg_key = tg_key
          target = target
        }
      ]
    ]) : item.key => item
  }

  protocol_map = {
    "TCP" = "Tcp"
    "UDP" = "Udp"
    "Tcp" = "Tcp"
    "Udp" = "Udp"
  }

  probe_protocol_map = {
    "TCP"   = "Tcp"
    "HTTP"  = "Http"
    "HTTPS" = "Https"
    "Tcp"   = "Tcp"
    "Http"  = "Http"
    "Https" = "Https"
  }
}

check "subnet_required_for_internal" {
  assert {
    condition     = !var.internal || local.frontend_subnet_id != null
    error_message = "Internal load balancers require subnet_ids or frontend_subnet_id."
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

check "listener_target_groups" {
  assert {
    condition = alltrue([
      for listener in var.listeners :
      contains(keys(var.target_groups), listener.target_group_key)
    ])
    error_message = "Each listener must reference a valid target_group_key."
  }
}

check "target_group_protocols" {
  assert {
    condition = alltrue([
      for tg in var.target_groups :
      contains(["TCP", "UDP", "Tcp", "Udp"], tg.protocol)
    ])
    error_message = "Target group protocol must be TCP or UDP."
  }
}

check "listener_protocols" {
  assert {
    condition = alltrue([
      for listener in var.listeners :
      contains(["TCP", "UDP", "Tcp", "Udp"], listener.protocol)
    ])
    error_message = "Listener protocol must be TCP or UDP."
  }
}

check "listener_ports_unique" {
  assert {
    condition = length(distinct([
      for listener in var.listeners : "${listener.port}/${listener.protocol}"
    ])) == length(var.listeners)
    error_message = "Each listener must use a unique port and protocol combination."
  }
}

check "health_check_path_required" {
  assert {
    condition = alltrue([
      for tg in var.target_groups :
      !tg.health_check_enabled ||
      !contains(["HTTP", "HTTPS", "Http", "Https"], upper(tg.health_check_protocol)) ||
      try(tg.health_check_request_path, null) != null
    ])
    error_message = "health_check_request_path is required when health_check_protocol is HTTP or HTTPS."
  }
}

resource "azurerm_public_ip" "frontend" {
  count = !var.internal && var.public_ip_address_id == null ? 1 : 0

  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.public_ip_zones

  tags = merge(var.tags, {
    Name = "${var.name}-pip"
  })
}

resource "azurerm_lb" "load_balancer" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  frontend_ip_configuration {
    name                          = "frontend"
    public_ip_address_id          = var.internal ? null : coalesce(var.public_ip_address_id, try(azurerm_public_ip.frontend[0].id, null))
    subnet_id                     = var.internal ? local.frontend_subnet_id : null
    private_ip_address_allocation = var.internal ? "Dynamic" : null
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "azurerm_lb_backend_address_pool" "target_group" {
  for_each = var.target_groups

  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = substr("${var.name}-${each.key}", 0, 80)
}

resource "azurerm_lb_probe" "probe" {
  for_each = var.target_groups

  loadbalancer_id     = azurerm_lb.load_balancer.id
  name                = substr("${var.name}-${each.key}-probe", 0, 80)
  protocol            = each.value.health_check_enabled ? local.probe_protocol_map[each.value.health_check_protocol] : local.protocol_map[each.value.protocol]
  port                = each.value.health_check_enabled ? coalesce(try(each.value.health_check_port, null), each.value.port) : each.value.port
  interval_in_seconds = each.value.health_check_interval_in_seconds
  number_of_probes    = each.value.health_check_number_of_probes
  request_path        = each.value.health_check_enabled && contains(["HTTP", "HTTPS", "Http", "Https"], each.value.health_check_protocol) ? each.value.health_check_request_path : null
}

resource "azurerm_lb_rule" "listener" {
  for_each = var.listeners

  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = substr("${var.name}-${each.key}", 0, 80)
  protocol                       = local.protocol_map[each.value.protocol]
  frontend_port                  = each.value.port
  backend_port                   = var.target_groups[each.value.target_group_key].port
  frontend_ip_configuration_name = "frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.target_group[each.value.target_group_key].id]
  probe_id                       = azurerm_lb_probe.probe[each.value.target_group_key].id
  enable_floating_ip             = each.value.enable_floating_ip
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
  disable_outbound_snat          = each.value.disable_outbound_snat
  load_distribution              = var.target_groups[each.value.target_group_key].load_distribution
}

resource "azurerm_lb_backend_address_pool_address" "attachment" {
  for_each = local.target_attachments

  name                    = coalesce(try(each.value.target.name, null), replace(each.value.target.ip_address, ".", "-"))
  backend_address_pool_id = azurerm_lb_backend_address_pool.target_group[each.value.tg_key].id
  virtual_network_id      = var.vnet_id
  ip_address              = each.value.target.ip_address
}
