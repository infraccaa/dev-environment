locals {
  env_id  = "${var.dev_name}-${var.app_name}"
  vm_name = "dev-${var.dev_name}-${var.app_name}"
}

module "hyperv_vm" {
  source = "../../modules/hyperv-vm"

  vm_name         = local.vm_name
  vm_template_vhd = var.vm_template_vhd
  vm_cpu          = var.vm_cpu
  vm_memory_mb    = var.vm_memory_mb
  dev_vswitch     = var.dev_vswitch
}

module "internal_db" {
  source = "../../modules/internal-db"

  db_server_internal = var.db_server_internal
  db_source          = var.db_source
  db_name_dev        = var.db_name_dev
}

module "route53_dns" {
  source = "../../modules/route53-dns"
  count  = var.external_access ? 1 : 0

  hosted_zone_id       = var.hosted_zone_id
  record_name          = "${var.dev_name}.${var.app_name}.dominio.com.br"
  fortinet_external_ip = var.fortinet_external_ip
}

module "fortinet_policy" {
  source = "../../modules/fortinet-policy"
  count  = var.external_access ? 1 : 0

  dev_name             = var.dev_name
  app_name             = var.app_name
  fortinet_external_ip = var.fortinet_external_ip
  assigned_port        = var.assigned_port
  app_internal_port    = var.app_internal_port
  vm_ip                = module.hyperv_vm.vm_ip
  dev_vlan_interface   = var.dev_vlan_interface
}
