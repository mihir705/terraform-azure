resource "random_password" "admin" {
  count = var.generate_password != null ? 1 : 0

  length           = var.generate_password.length
  special          = var.generate_password.special
  override_special = var.generate_password.override_special
}

locals {
  admin_password = coalesce(
    var.admin_password,
    try(random_password.admin[0].result, null)
  )

  custom_data = coalesce(
    var.custom_data_base64,
    var.custom_data != null ? base64encode(var.custom_data) : null
  )

  os_disk_defaults = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  resolved_os_disk = merge(local.os_disk_defaults, var.os_disk)
}

check "image_source_required" {
  assert {
    condition     = var.source_image_id != null || var.source_image_reference != null
    error_message = "Provide source_image_id or source_image_reference."
  }
}

check "image_source_exclusive" {
  assert {
    condition     = var.source_image_id == null || var.source_image_reference == null
    error_message = "Use either source_image_id or source_image_reference, not both."
  }
}

check "password_or_ssh_required" {
  assert {
    condition = (
      var.disable_password_authentication && var.admin_ssh_key != null
      ) || (
      !var.disable_password_authentication && (
        var.admin_password != null || var.generate_password != null
      )
    )
    error_message = "Provide admin_ssh_key when disable_password_authentication is true, or admin_password/generate_password when false."
  }
}

check "custom_data_exclusive" {
  assert {
    condition     = var.custom_data == null || var.custom_data_base64 == null
    error_message = "Use either custom_data or custom_data_base64, not both."
  }
}

check "static_private_ip" {
  assert {
    condition     = var.private_ip_address_allocation != "Static" || var.private_ip_address != null
    error_message = "private_ip_address is required when private_ip_address_allocation is Static."
  }
}

check "data_disk_luns_unique" {
  assert {
    condition = length(distinct([
      for disk in var.data_disks : disk.lun
    ])) == length(var.data_disks)
    error_message = "Each data_disks entry must use a unique lun."
  }
}

resource "azurerm_public_ip" "this" {
  count = var.create_public_ip ? 1 : 0

  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  zones               = var.availability_zone != null ? [var.availability_zone] : null

  tags = merge(var.tags, {
    Name = "${var.name}-pip"
  })
}

resource "azurerm_network_interface" "this" {
  name                = "${var.name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.this[0].id : null
  }

  tags = merge(var.tags, {
    Name = "${var.name}-nic"
  })
}

resource "azurerm_network_interface_security_group_association" "this" {
  count = var.nsg_id != null ? 1 : 0

  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.nsg_id
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.size
  admin_username      = var.admin_username
  admin_password      = var.disable_password_authentication ? null : local.admin_password
  zone                = var.availability_zone

  disable_password_authentication = var.disable_password_authentication
  network_interface_ids           = [azurerm_network_interface.this.id]
  custom_data                     = local.custom_data

  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_key != null ? [var.admin_ssh_key] : []

    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_reference != null ? [var.source_image_reference] : []

    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  source_image_id = var.source_image_id

  os_disk {
    name                   = "${var.name}-osdisk"
    caching                = local.resolved_os_disk.caching
    storage_account_type   = local.resolved_os_disk.storage_account_type
    disk_size_gb           = try(local.resolved_os_disk.disk_size_gb, null)
    disk_encryption_set_id = try(local.resolved_os_disk.disk_encryption_set_id, null)
  }

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_uri != null ? [var.boot_diagnostics_storage_uri] : []

    content {
      storage_account_uri = boot_diagnostics.value
    }
  }

  patch_mode                 = var.patch_mode
  allow_extension_operations = true
  provision_vm_agent         = true

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_managed_disk" "data" {
  for_each = var.data_disks

  name                   = "${var.name}-${each.key}-disk"
  location               = var.location
  resource_group_name    = var.resource_group_name
  storage_account_type   = each.value.storage_account_type
  create_option          = each.value.create_option
  disk_size_gb           = each.value.disk_size_gb
  zone                   = var.availability_zone
  disk_encryption_set_id = try(each.value.disk_encryption_set_id, null)

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}-disk"
  })
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = var.data_disks

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = each.value.lun
  caching            = each.value.caching
}
