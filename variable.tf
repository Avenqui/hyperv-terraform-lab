variable "servers" {
  description = "Hyper-V Virtual machines"

  type = map(object({
    cpu = number
    ram = number
  }))

  default = {
    "SRV-TEST01" = {
      cpu = 2
      ram = 4
    }

    "SRV-TEST02" = {
      cpu = 2
      ram = 4
    }

    "SRV-TEST03" = {
      cpu = 2
      ram = 4
    }
  }
}