output "vm_name" {
  value = hyperv_machine_instance.dev_vm.name
}

output "vm_ip" {
  value = local.vm_ip
}
