resource "null_resource" "db_clone" {
  triggers = {
    db_source   = var.db_source
    db_name_dev = var.db_name_dev
  }

  provisioner "local-exec" {
    command = "pwsh -File ../../scripts/db_clone.ps1 -DbServer ${var.db_server_internal} -Source ${var.db_source} -Target ${var.db_name_dev}"
  }
}
