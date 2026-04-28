resource "fortios_firewall_vip" "dev_vip" {
  name        = "vip-dev-${var.dev_name}-${var.app_name}"
  extip       = var.fortinet_external_ip
  extport     = tostring(var.assigned_port)
  portforward = "enable"
  protocol    = "tcp"

  mappedip {
    range = var.vm_ip
  }

  mappedport = var.app_internal_port
}

resource "fortios_firewall_policy" "dev_policy" {
  name   = "pol-dev-${var.dev_name}-${var.app_name}"
  action = "accept"

  srcintf { name = "wan" }
  dstintf { name = var.dev_vlan_interface }
  srcaddr { name = "all" }
  dstaddr { name = fortios_firewall_vip.dev_vip.name }
  service { name = "ALL" }

  logtraffic = "all"
}
