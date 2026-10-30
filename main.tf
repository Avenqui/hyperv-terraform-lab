resource "hyperv_vm" "servers" {
  for_each = var.servers

  name       = each.key
  generation = 2

  cpu = {
    count = each.value.cpu
  }
  memory = {
    dynamic       = false
    startup_bytes = each.value.ram * 1024 * 1024 * 1024
  }

  hard_disk_drive = [
    {
      controller_type     = "SCSI"
      controller_number   = 0
      controller_location = 0
      path                = hyperv_vhd.servers[each.key].path
    }
  ]

  network_adapter = [
    {
      name        = "Network Adapter"
      switch_name = "vSwitch-External"
    }
  ]
}

resource "hyperv_vhd" "servers" {
  for_each = var.servers

  path        = "C:/Hyper-V/VMs/${each.key}/${each.key}.vhdx"
  source_path = "C:/Hyper-V/Templates/tempWin2022.vhdx"
}