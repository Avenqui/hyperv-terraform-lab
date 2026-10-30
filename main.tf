resource "hyperv_vm" "srv_test01" {
  name       = "SRV-TEST01"
  generation = 2
  cpu = {
    count = 2
  }
  memory = {
    dynamic = false
    # startup_bytes = 4294967296
    # min_bytes     = 2147483548
    # max_bytes     = 6442450944
    startup_bytes = 4294967296
  }
  hard_disk_drive = [{
    controller_type     = "SCSI"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_image_file.srv_test01_disk.destination_path
  }]
  network_adapter = [{
    name        = "Network Adapter"
    switch_name = "vSwitch-External"
  }]
}

resource "hyperv_image_file" "srv_test01_disk" {
  source_path      = "C:/Hyper-V/Templates/tempWin2022.vhdx"
  destination_path = "C:/Hyper-V/VMs/SRV-TEST01/SRV-TEST01.vhdx"

  keep_on_destroy = false
}