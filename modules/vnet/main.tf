locals {
  name_prefix = var.name

  public_subnet_keys  = sort(keys(var.public_subnets))
  private_subnet_keys = sort(keys(var.private_subnets))

  first_public_subnet_key = length(local.public_subnet_keys) > 0 ? local.public_subnet_keys[0] : null

  nat_gateways = var.enable_nat_gateway ? (
    var.one_nat_gateway_per_az ? merge([
      for az in distinct([for subnet in var.public_subnets : subnet.availability_zone]) : {
        (az) = [
          for key in local.public_subnet_keys : key
          if var.public_subnets[key].availability_zone == az
        ][0]
      }
      ]...) : local.first_public_subnet_key != null ? {
      (var.public_subnets[local.first_public_subnet_key].availability_zone) = local.first_public_subnet_key
    } : {}
  ) : {}

  private_route_table_keys = var.enable_nat_gateway && var.one_nat_gateway_per_az ? local.private_subnet_keys : (
    length(local.private_subnet_keys) > 0 ? ["default"] : []
  )

  private_route_table_nat_az = var.enable_nat_gateway && !var.one_nat_gateway_per_az && local.first_public_subnet_key != null ? (
    var.public_subnets[local.first_public_subnet_key].availability_zone
  ) : null

  private_nacl_ingress_rules = coalesce(var.private_nacl_ingress_rules, [
    {
      priority                   = 100
      name                       = "allow-vnet-inbound"
      protocol                   = "*"
      access                     = "Allow"
      source_address_prefix      = var.address_space[0]
      destination_address_prefix = "*"
    },
    {
      priority                   = 110
      name                       = "allow-ephemeral-tcp-inbound"
      protocol                   = "Tcp"
      access                     = "Allow"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      destination_port_range     = "1024-65535"
    },
    {
      priority                   = 120
      name                       = "allow-ephemeral-udp-inbound"
      protocol                   = "Udp"
      access                     = "Allow"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      destination_port_range     = "1024-65535"
    },
  ])

  common_tags = merge(var.tags, {
    Name = local.name_prefix
  })
}

check "public_subnets_required" {
  assert {
    condition     = length(var.public_subnets) >= 1
    error_message = "At least one public subnet is required."
  }
}

check "private_subnets_required" {
  assert {
    condition     = length(var.private_subnets) >= 1
    error_message = "At least one private subnet is required."
  }
}

check "nat_requires_public_subnet" {
  assert {
    condition     = !var.enable_nat_gateway || length(var.public_subnets) > 0
    error_message = "enable_nat_gateway requires at least one public subnet."
  }
}

check "nat_strategy_exclusive" {
  assert {
    condition     = !(var.single_nat_gateway && var.one_nat_gateway_per_az)
    error_message = "single_nat_gateway and one_nat_gateway_per_az cannot both be true."
  }
}

check "one_nat_per_az_implies_multiple_nat" {
  assert {
    condition     = !var.one_nat_gateway_per_az || !var.single_nat_gateway
    error_message = "one_nat_gateway_per_az requires single_nat_gateway = false."
  }
}

check "private_subnet_nat_az_coverage" {
  assert {
    condition = !var.enable_nat_gateway || !var.one_nat_gateway_per_az || alltrue([
      for subnet in var.private_subnets :
      contains(keys(local.nat_gateways), subnet.availability_zone)
    ])
    error_message = "Each private subnet AZ must have a public subnet in the same AZ when one_nat_gateway_per_az is enabled."
  }
}

check "nat_per_az_requires_matching_public_subnet" {
  assert {
    condition = !var.one_nat_gateway_per_az || alltrue([
      for az in distinct([for subnet in var.private_subnets : subnet.availability_zone]) :
      contains(distinct([for subnet in var.public_subnets : subnet.availability_zone]), az)
    ])
    error_message = "one_nat_gateway_per_az requires a public subnet in every private subnet availability zone."
  }
}

check "public_nacl_priorities_unique" {
  assert {
    condition = length(distinct([
      for rule in var.public_nacl_ingress_rules : rule.priority
    ])) == length(var.public_nacl_ingress_rules)
    error_message = "public_nacl_ingress_rules priority values must be unique."
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  tags = local.common_tags
}

resource "azurerm_subnet" "public" {
  for_each = var.public_subnets

  name                 = "${local.name_prefix}-public-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
}

resource "azurerm_subnet" "private" {
  for_each = var.private_subnets

  name                 = "${local.name_prefix}-private-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
}

resource "azurerm_public_ip" "nat" {
  for_each = local.nat_gateways

  name                = "${local.name_prefix}-nat-pip-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [each.key]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-pip-${each.key}"
  })
}

resource "azurerm_nat_gateway" "nat" {
  for_each = local.nat_gateways

  name                    = "${local.name_prefix}-nat-${each.key}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  zones                   = [each.key]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-${each.key}"
  })
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  for_each = local.nat_gateways

  nat_gateway_id       = azurerm_nat_gateway.nat[each.key].id
  public_ip_address_id = azurerm_public_ip.nat[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  for_each = var.enable_nat_gateway ? var.private_subnets : {}

  subnet_id = azurerm_subnet.private[each.key].id
  nat_gateway_id = var.one_nat_gateway_per_az ? azurerm_nat_gateway.nat[
    each.value.availability_zone
  ].id : azurerm_nat_gateway.nat[local.private_route_table_nat_az].id
}

resource "azurerm_route_table" "public" {
  name                = "${local.name_prefix}-public-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name           = "default-internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
    Tier = "public"
  })
}

resource "azurerm_route_table" "private" {
  for_each = toset(local.private_route_table_keys)

  name                = var.one_nat_gateway_per_az ? "${local.name_prefix}-private-rt-${each.key}" : "${local.name_prefix}-private-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(local.common_tags, {
    Name = var.one_nat_gateway_per_az ? "${local.name_prefix}-private-rt-${each.key}" : "${local.name_prefix}-private-rt"
    Tier = "private"
  })
}

resource "azurerm_subnet_route_table_association" "public" {
  for_each = var.public_subnets

  subnet_id      = azurerm_subnet.public[each.key].id
  route_table_id = azurerm_route_table.public.id
}

resource "azurerm_subnet_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id      = azurerm_subnet.private[each.key].id
  route_table_id = var.one_nat_gateway_per_az ? azurerm_route_table.private[each.key].id : azurerm_route_table.private["default"].id
}

resource "azurerm_network_security_group" "public" {
  count = var.create_public_nacl ? 1 : 0

  name                = "${local.name_prefix}-public-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-nsg"
    Tier = "public"
  })
}

resource "azurerm_network_security_rule" "public_ingress" {
  for_each = var.create_public_nacl ? {
    for rule in var.public_nacl_ingress_rules : "${rule.priority}-ingress" => rule
  } : {}

  name                        = coalesce(each.value.name, "ingress-${each.value.priority}")
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = try(each.value.source_port_range, "*")
  destination_port_range      = try(each.value.destination_port_range, "*")
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = coalesce(each.value.destination_address_prefix, "*")
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public[0].name
}

resource "azurerm_network_security_rule" "public_egress" {
  for_each = var.create_public_nacl ? {
    for rule in var.public_nacl_egress_rules : "${rule.priority}-egress" => rule
  } : {}

  name                        = coalesce(each.value.name, "egress-${each.value.priority}")
  priority                    = each.value.priority
  direction                   = "Outbound"
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = try(each.value.source_port_range, "*")
  destination_port_range      = try(each.value.destination_port_range, "*")
  source_address_prefix       = coalesce(each.value.source_address_prefix, "*")
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public[0].name
}

resource "azurerm_network_security_group" "private" {
  count = var.create_private_nacl ? 1 : 0

  name                = "${local.name_prefix}-private-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-nsg"
    Tier = "private"
  })
}

resource "azurerm_network_security_rule" "private_ingress" {
  for_each = var.create_private_nacl ? {
    for rule in local.private_nacl_ingress_rules : "${rule.priority}-ingress" => rule
  } : {}

  name                        = coalesce(each.value.name, "ingress-${each.value.priority}")
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = try(each.value.source_port_range, "*")
  destination_port_range      = try(each.value.destination_port_range, "*")
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = coalesce(each.value.destination_address_prefix, "*")
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private[0].name
}

resource "azurerm_network_security_rule" "private_egress" {
  for_each = var.create_private_nacl ? {
    for rule in var.private_nacl_egress_rules : "${rule.priority}-egress" => rule
  } : {}

  name                        = coalesce(each.value.name, "egress-${each.value.priority}")
  priority                    = each.value.priority
  direction                   = "Outbound"
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = try(each.value.source_port_range, "*")
  destination_port_range      = try(each.value.destination_port_range, "*")
  source_address_prefix       = coalesce(each.value.source_address_prefix, "*")
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private[0].name
}

resource "azurerm_subnet_network_security_group_association" "public" {
  for_each = var.create_public_nacl ? var.public_subnets : {}

  subnet_id                 = azurerm_subnet.public[each.key].id
  network_security_group_id = azurerm_network_security_group.public[0].id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  for_each = var.create_private_nacl ? var.private_subnets : {}

  subnet_id                 = azurerm_subnet.private[each.key].id
  network_security_group_id = azurerm_network_security_group.private[0].id
}
