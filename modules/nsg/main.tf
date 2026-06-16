locals {
  description = coalesce(var.description, "Network security group ${var.name}")

  protocol_map = {
    "tcp"    = "Tcp"
    "udp"    = "Udp"
    "icmp"   = "Icmp"
    "icmpv6" = "Icmp"
    "-1"     = "*"
    "*"      = "*"
    "Tcp"    = "Tcp"
    "Udp"    = "Udp"
    "Icmp"   = "Icmp"
  }

  default_egress_rule = {
    name                       = "allow-all-outbound-ipv4"
    description                = "All outbound IPv4"
    protocol                   = "*"
    destination_address_prefix = "*"
  }

  egress_rules = concat(
    coalesce(var.egress_rules, []),
    var.egress_rules == null ? [local.default_egress_rule] : []
  )

  ingress_rule_expansions = flatten([
    for rule_idx, rule in var.ingress_rules : concat(
      rule.source_address_prefix != null ? [{
        key         = "ingress-${rule_idx}-prefix"
        rule        = rule
        rule_idx    = rule_idx
        prefix      = rule.source_address_prefix
        dest_prefix = try(rule.destination_address_prefix, null)
        ref_nsg     = null
        self_ref    = false
        source_asg  = rule.source_application_security_group_ids
        dest_asg    = rule.destination_application_security_group_ids
      }] : [],
      [
        for prefix_idx, prefix in rule.source_address_prefixes : {
          key         = "ingress-${rule_idx}-prefix-${prefix_idx}"
          rule        = rule
          rule_idx    = rule_idx
          prefix      = prefix
          dest_prefix = try(rule.destination_address_prefix, null)
          ref_nsg     = null
          self_ref    = false
          source_asg  = rule.source_application_security_group_ids
          dest_asg    = rule.destination_application_security_group_ids
        }
      ],
      length(rule.source_application_security_group_ids) > 0 && try(rule.source_address_prefix, null) == null && length(rule.source_address_prefixes) == 0 ? [{
        key         = "ingress-${rule_idx}-asg"
        rule        = rule
        rule_idx    = rule_idx
        prefix      = null
        dest_prefix = try(rule.destination_address_prefix, null)
        ref_nsg     = null
        self_ref    = false
        source_asg  = rule.source_application_security_group_ids
        dest_asg    = rule.destination_application_security_group_ids
      }] : [],
      try(rule.referenced_network_security_group_id, null) != null ? [{
        key         = "ingress-${rule_idx}-nsg"
        rule        = rule
        rule_idx    = rule_idx
        prefix      = "VirtualNetwork"
        dest_prefix = try(rule.destination_address_prefix, null)
        ref_nsg     = rule.referenced_network_security_group_id
        self_ref    = false
        source_asg  = rule.source_application_security_group_ids
        dest_asg    = rule.destination_application_security_group_ids
      }] : [],
      rule.self_reference ? [{
        key         = "ingress-${rule_idx}-self"
        rule        = rule
        rule_idx    = rule_idx
        prefix      = "VirtualNetwork"
        dest_prefix = try(rule.destination_address_prefix, null)
        ref_nsg     = null
        self_ref    = true
        source_asg  = rule.source_application_security_group_ids
        dest_asg    = rule.destination_application_security_group_ids
      }] : []
    )
  ])

  egress_rule_expansions = flatten([
    for rule_idx, rule in local.egress_rules : concat(
      rule.destination_address_prefix != null ? [{
        key           = "egress-${rule_idx}-prefix"
        rule          = rule
        rule_idx      = rule_idx
        prefix        = rule.destination_address_prefix
        source_prefix = try(rule.source_address_prefix, null)
        ref_nsg       = null
        self_ref      = false
        source_asg    = rule.source_application_security_group_ids
        dest_asg      = rule.destination_application_security_group_ids
      }] : [],
      [
        for prefix_idx, prefix in rule.destination_address_prefixes : {
          key           = "egress-${rule_idx}-prefix-${prefix_idx}"
          rule          = rule
          rule_idx      = rule_idx
          prefix        = prefix
          source_prefix = try(rule.source_address_prefix, null)
          ref_nsg       = null
          self_ref      = false
          source_asg    = rule.source_application_security_group_ids
          dest_asg      = rule.destination_application_security_group_ids
        }
      ],
      try(rule.referenced_network_security_group_id, null) != null ? [{
        key           = "egress-${rule_idx}-nsg"
        rule          = rule
        rule_idx      = rule_idx
        prefix        = null
        source_prefix = try(rule.source_address_prefix, null)
        ref_nsg       = rule.referenced_network_security_group_id
        self_ref      = false
        source_asg    = rule.source_application_security_group_ids
        dest_asg      = rule.destination_application_security_group_ids
      }] : [],
      rule.self_reference ? [{
        key           = "egress-${rule_idx}-self"
        rule          = rule
        rule_idx      = rule_idx
        prefix        = null
        source_prefix = try(rule.source_address_prefix, null)
        ref_nsg       = null
        self_ref      = true
        source_asg    = rule.source_application_security_group_ids
        dest_asg      = rule.destination_application_security_group_ids
      }] : []
    )
  ])
}

check "ingress_rule_has_target" {
  assert {
    condition = alltrue([
      for rule in var.ingress_rules :
      try(rule.source_address_prefix, null) != null ||
      length(rule.source_address_prefixes) > 0 ||
      try(rule.referenced_network_security_group_id, null) != null ||
      rule.self_reference ||
      length(rule.source_application_security_group_ids) > 0
    ])
    error_message = "Each ingress rule must define at least one source: source_address_prefix, source_address_prefixes, referenced_network_security_group_id, self_reference, or source_application_security_group_ids."
  }
}

check "egress_rule_has_target" {
  assert {
    condition = alltrue([
      for rule in local.egress_rules :
      try(rule.destination_address_prefix, null) != null ||
      length(rule.destination_address_prefixes) > 0 ||
      try(rule.referenced_network_security_group_id, null) != null ||
      rule.self_reference ||
      length(rule.destination_application_security_group_ids) > 0
    ])
    error_message = "Each egress rule must define at least one destination: destination_address_prefix, destination_address_prefixes, referenced_network_security_group_id, self_reference, or destination_application_security_group_ids."
  }
}

check "tcp_udp_ports_required" {
  assert {
    condition = alltrue(concat(
      [
        for rule in var.ingress_rules :
        contains(["tcp", "udp", "Tcp", "Udp"], lower(rule.protocol)) == false || (
          try(rule.destination_port_range, null) != null
        )
      ],
      [
        for rule in local.egress_rules :
        contains(["tcp", "udp", "Tcp", "Udp"], lower(rule.protocol)) == false || (
          try(rule.destination_port_range, null) != null
        )
      ]
    ))
    error_message = "destination_port_range is required when protocol is tcp or udp."
  }
}

check "valid_protocols" {
  assert {
    condition = alltrue(concat(
      [
        for rule in var.ingress_rules :
        contains(keys(local.protocol_map), rule.protocol)
      ],
      [
        for rule in local.egress_rules :
        contains(keys(local.protocol_map), rule.protocol)
      ]
    ))
    error_message = "protocol must be tcp, udp, icmp, icmpv6, -1, or * (Azure: Tcp, Udp, Icmp, *)."
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    Name        = var.name
    Description = local.description
  })
}

resource "azurerm_network_security_rule" "ingress" {
  for_each = {
    for item in local.ingress_rule_expansions : item.key => item
  }

  name                                       = coalesce(try(each.value.rule.name, null), "ingress-${each.value.rule_idx}")
  priority                                   = coalesce(try(each.value.rule.priority, null), 100 + each.value.rule_idx)
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = local.protocol_map[each.value.rule.protocol]
  source_port_range                          = coalesce(try(each.value.rule.source_port_range, null), "*")
  destination_port_range                     = coalesce(try(each.value.rule.destination_port_range, null), "*")
  source_address_prefix                      = each.value.prefix
  destination_address_prefix                 = coalesce(each.value.dest_prefix, "*")
  source_application_security_group_ids      = length(each.value.source_asg) > 0 ? each.value.source_asg : null
  destination_application_security_group_ids = length(each.value.dest_asg) > 0 ? each.value.dest_asg : null
  resource_group_name                        = var.resource_group_name
  network_security_group_name                = azurerm_network_security_group.nsg.name

  description = try(each.value.rule.description, null)

  lifecycle {
    precondition {
      condition     = each.value.prefix != null || length(each.value.source_asg) > 0
      error_message = "Each ingress rule requires source_address_prefix or source_application_security_group_ids."
    }
  }
}

resource "azurerm_network_security_rule" "egress" {
  for_each = {
    for item in local.egress_rule_expansions : item.key => item
  }

  name                                       = coalesce(try(each.value.rule.name, null), "egress-${each.value.rule_idx}")
  priority                                   = coalesce(try(each.value.rule.priority, null), 100 + each.value.rule_idx)
  direction                                  = "Outbound"
  access                                     = "Allow"
  protocol                                   = local.protocol_map[each.value.rule.protocol]
  source_port_range                          = coalesce(try(each.value.rule.source_port_range, null), "*")
  destination_port_range                     = coalesce(try(each.value.rule.destination_port_range, null), "*")
  source_address_prefix                      = coalesce(each.value.source_prefix, "*")
  destination_address_prefix                 = each.value.prefix
  source_application_security_group_ids      = length(each.value.source_asg) > 0 ? each.value.source_asg : null
  destination_application_security_group_ids = length(each.value.dest_asg) > 0 ? each.value.dest_asg : null
  resource_group_name                        = var.resource_group_name
  network_security_group_name                = azurerm_network_security_group.nsg.name

  description = try(each.value.rule.description, null)
}
