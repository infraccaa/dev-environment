# Manual de Preenchimento

## 1) Por ticket (sempre)
Preencher em `environments/dev/terraform.tfvars`:
- `dev_name`
- `app_name`
- `app_stack`
- `ado_org`, `ado_project`, `ado_repo`, `branch`
- `db_source`, `db_name_dev`
- `vm_template_vhd`, `vm_cpu`, `vm_memory_mb`
- `external_access`
- `shutdown_date`, `destroy_date`

## 2) Quando `external_access = true`
Preencher tambem:
- `assigned_port` (range reservado)
- `fortinet_external_ip`
- `hosted_zone_id`
- `app_internal_port`

## 3) Uma vez por ambiente/plataforma
Definir em `environments/dev/terraform.tfvars` ou variable group do pipeline:
- `hyperv_host`
- `dev_vswitch`
- `db_server_internal`

## 4) Segredos (nao versionar)
Configurar no Azure DevOps Variable Group ligado a Key Vault/Vault:
- `FORTINET_API_TOKEN`
- `ADO_PAT`
- credenciais WinRM do host Hyper-V
- credenciais de servico do banco

## 5) Ajustes manuais iniciais de infraestrutura
- Habilitar WinRM HTTPS no host Hyper-V (porta 5986).
- Criar token REST API no Fortinet com escopo minimo.
- Garantir permissao de dump/restore no banco interno.
- Validar backend remoto de state e lock.

## 6) Validacao antes de executar pipeline
- `terraform fmt -check`
- `terraform validate`
- `terraform plan -var-file=terraform.tfvars`
- confirmar porta externa livre (se aplicavel)
