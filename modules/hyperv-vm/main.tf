resource "hyperv_machine_instance" "dev_vm" {
  name             = var.vm_name
  processor_count  = var.vm_cpu
  static_memory_mb = var.vm_memory_mb
  generation       = 2

  hard_disk_drives {
    path = "C:/Hyper-V/VHDs/${var.vm_name}.vhdx"
  }

  network_adaptors {
    name        = "Ethernet"
    switch_name = var.dev_vswitch
  }
}

# TODO_MANUAL: substituir por descoberta real de IP (DHCP/IPAM/guest tools)
locals {
  vm_ip = "192.168.100.10"
}
