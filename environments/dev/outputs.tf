output "vm_name" {
  value = module.hyperv_vm.vm_name
}

output "vm_ip" {
  value = module.hyperv_vm.vm_ip
}

output "internal_url" {
  value = "http://${module.hyperv_vm.vm_ip}"
}

output "external_url" {
  value = var.external_access ? "https://${var.dev_name}.${var.app_name}.dominio.com.br:${var.assigned_port}" : null
}
