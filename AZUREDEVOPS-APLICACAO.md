# Aplicacao no Azure DevOps

## 1. Estrutura no repositorio
- Commit da estrutura IaC e pipeline.
- Arquivo de pipeline: pipeline/azure-pipelines.yml.
- Arquivo de variaveis por ambiente: environments/dev/terraform.tfvars.

## 2. Service connections e permissoes
- AWS: usar credenciais com permissao minima para Route53 (somente zona alvo).
- Se backend remoto usar Azure Storage, garantir permissao no storage account.
- Agente Microsoft-hosted funciona para validacao e ansible basico.

## 3. Variable Group
Criar Variable Group chamado iac-dev-shared e marcar segredos:
- HYPERV_USERNAME
- HYPERV_PASSWORD
- FORTINET_API_TOKEN
- FORTINET_HOSTNAME
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- ADO_PAT

Opcional: vincular Variable Group ao Key Vault para rotacao centralizada.

## 4. Pipeline
No Azure DevOps:
1. Pipelines -> New pipeline
2. Repositorio: infra-dev-environments
3. Existing Azure Pipelines YAML
4. Path: pipeline/azure-pipelines.yml
5. Save

## 5. Execucao operacional por ticket
1. Criar branch de trabalho
2. Copiar environments/dev/terraform.tfvars.tmpl para environments/dev/terraform.tfvars
3. Preencher campos do ticket
4. Commit + push
5. Run pipeline informando o parametro tfvarsFile (default: environments/dev/terraform.tfvars)

## 6. Ordem de execucao dos estagios
- Validate: fmt, validate, plan
- PlanApply: apply e export do IP da VM
- ConfigureVM: ansible no IP gerado

## 7. Campos manuais obrigatorios
Conforme MANUAL-PREENCHIMENTO.md:
- ticket: dev_name, app_name, app_stack, branch, db_source, db_name_dev, lifecycle
- externo: hosted_zone_id, assigned_port, fortinet_external_ip
- base: hyperv_host, dev_vswitch, db_server_internal

## 8. Go-live checklist
- WinRM HTTPS ativo no Hyper-V
- token Fortinet valido
- porta externa reservada (se external_access=true)
- backend Terraform com lock habilitado
- pipeline com acesso ao Variable Group
