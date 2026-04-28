# infra-dev-environments

Arquitetura base para provisionamento de ambientes de desenvolvimento sob demanda via Terraform + Ansible + Azure DevOps Pipeline.

## Fluxo
1. Analista preenche `environments/dev/terraform.tfvars` a partir de `terraform.tfvars.tmpl`.
2. Pipeline executa: VHD clone -> Terraform -> DB clone -> Ansible -> notificacao.
3. Lifecycle job aplica shutdown/destroy por data.

## Estrutura
- `modules/`: modulos Terraform reutilizaveis.
- `environments/dev/`: composicao principal de infraestrutura.
- `ansible/`: playbook e roles de configuracao da VM.
- `pipeline/`: pipeline Azure DevOps.
- `scripts/`: scripts operacionais (db clone, vhd clone, lifecycle).

## Campos manuais obrigatorios
Veja `MANUAL-PREENCHIMENTO.md`.
# infra-dev-environment
# infra-dev-environment
# dev-environment
# dev-environment
