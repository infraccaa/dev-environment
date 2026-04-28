variable "dev_name" { type = string }
variable "app_name" { type = string }
variable "app_stack" { type = string }

variable "ado_org" { type = string }
variable "ado_project" { type = string }
variable "ado_repo" { type = string }
variable "branch" { type = string }

variable "db_server_internal" { type = string }
variable "db_source" { type = string }
variable "db_name_dev" { type = string }

variable "hyperv_host" { type = string }
variable "hyperv_username" {
  type      = string
  sensitive = true
}
variable "hyperv_password" {
  type      = string
  sensitive = true
}
variable "vm_template_vhd" { type = string }
variable "vm_cpu" { type = number }
variable "vm_memory_mb" { type = number }
variable "dev_vswitch" { type = string }

variable "external_access" { type = bool }
variable "app_internal_port" { type = string }
variable "fortinet_external_ip" { type = string }
variable "assigned_port" { type = number }
variable "hosted_zone_id" { type = string }

variable "dev_vlan_interface" {
  type    = string
  default = "lan"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "fortinet_hostname" { type = string }
variable "fortinet_api_token" {
  type      = string
  sensitive = true
}

variable "shutdown_date" { type = string }
variable "destroy_date" { type = string }
