Ambientes de Desenvolvimento
Infraestrutura sob Demanda com IaC
Guia de Arquitetura, Configuração e Execução

1. Visão Geral

Este documento descreve a arquitetura, os pré-requisitos de configuração e o passo a passo de execução para provisionar ambientes de desenvolvimento sob demanda. O processo é iniciado manualmente pelo analista de infraestrutura a partir de um ticket aberto pelo desenvolvedor.

## Cada ambiente de desenvolvimento é composto por:
Uma máquina virtual no Hyper-V interno, clonada a partir de um template baseado em homologação.
Um banco de dados próprio, restaurado a partir de um dump do banco de homologação.
Um ou mais registros DNS, permitindo que um mesmo desenvolvedor possua múltiplos ambientes ativos simultaneamente.
Regras de firewall no Fortinet e registros no Route 53, criados condicionalmente quando o acesso externo for necessário.

2. Arquitetura do Ambiente

2.1 Ambientes Existentes

2.2 Stack de IaC

2.3 Fluxo de Criação
## O fluxo de criação segue as etapas abaixo, todas orquestradas pelo Azure Pipeline:
Analista recebe o ticket e preenche o arquivo de variáveis (tfvars).
Pipeline é executado manualmente no Azure DevOps com as variáveis do ticket.
Terraform provisiona a VM no Hyper-V.
Script realiza dump do banco de homologação e restauração com novo nome.
Terraform cria o registro DNS interno.
Terraform cria registro no Route 53 e regras no Fortinet (somente se acesso externo).
Ansible configura o servidor: stack, usuário, repositório e variáveis de ambiente.
Pipeline notifica o analista com URL, credenciais e datas de lifecycle.

2.4 DNS e Acesso por Dev
## Um desenvolvedor pode ter múltiplos ambientes ativos ao mesmo tempo. Cada ambiente recebe seu próprio subdomínio, seguindo o padrão:

# Padrão de nomenclatura
{dev}.{app}.dominio.com.br         → acesso interno
{dev}.{app}.dominio.com.br:{porta} → acesso externo (quando habilitado)

# Exemplos
joao.portal.dominio.com.br
joao.moodle.dominio.com.br:8443
maria.erp.dominio.com.br:8444



3. Pré-Requisitos e Configuração

3.1 Hyper-V — WinRM para o Terraform
## O provider Terraform para Hyper-V (taliesins/hyperv) utiliza WinRM para se comunicar com o host. Execute no host Hyper-V:

# Habilitar WinRM com HTTPS (porta 5986)
winrm quickconfig -q
winrm set winrm/config/listener?Address=*+Transport=HTTPS @{Port="5986"}

# Criar certificado autoassinado
$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbprint $cert.Thumbprint -Force

# Liberar porta no firewall local
New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow


3.2 Fortinet — API Token
## O provider fortios autentica via API Token (não usuário/senha). Para criar o token no FortiGate:

FortiGate → System → Administrators → Create New → REST API Admin
→ Defina os perfis de acesso necessários (Firewall Policy, VIP, DNS)
→ Copie o token gerado para o Azure Key Vault / Vault

3.3 Azure DevOps — PAT para Clone de Repositório
## O Ansible utiliza um Personal Access Token (PAT) para clonar repositórios do Azure DevOps durante a configuração do ambiente. Configure o PAT com as permissões mínimas:
Code: Read
Escopo: somente os projetos necessários

Armazene o PAT no Azure Key Vault ou HashiCorp Vault. Nunca inclua no código ou no arquivo de variáveis.

3.4 Backend do Terraform — State Separado por Ambiente
## Cada ambiente de dev deve ter seu próprio state file, permitindo destroy independente. Configure um backend remoto:

# backend.tf
terraform {
backend "s3" {
bucket         = "terraform-states-dev"
key            = "dev/${dev_name}/${app_name}/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-lock"
}
}

# Alternativa: Azure Blob Storage
terraform {
backend "azurerm" {
resource_group_name  = "rg-terraform"
storage_account_name = "tfstatedev"
container_name       = "tfstate"
key                  = "dev/${dev_name}.${app_name}.tfstate"
}
}

3.5 Servidor de Banco de Dados Interno
## O servidor de banco interno (SQL Server, MySQL ou PostgreSQL) deve ter:
Usuário de serviço com permissão para criar novos databases.
Acesso liberado pela VLAN de gerência (para o pipeline executar dump/restore).
Espaço em disco dimensionado para suportar múltiplas cópias dos bancos de homologação.


4. Estrutura do Repositório IaC

infra-dev-environments/
├── modules/
│   ├── hyperv-vm/            ← provider taliesins/hyperv
│   ├── internal-db/          ← scripts de dump/restore
│   ├── route53-dns/          ← registro DNS externo
│   └── fortinet-policy/      ← VIP + policy de acesso externo
│
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars.tmpl   ← template preenchido pelo analista
│
├── ansible/
│   ├── roles/
│   │   ├── create_user/      ← cria usuário, senha temporária
│   │   ├── deploy_app/       ← clona repositório do Azure DevOps
│   │   ├── configure_env/    ← injeta variáveis de ambiente
│   │   ├── php/
│   │   ├── dotnet/
│   │   ├── moodle/
│   │   └── angular/
│   └── playbook-dev-setup.yml
│
├── scripts/
│   ├── db_clone.sh           ← dump do banco de homolog + restore com novo nome
│   ├── vhd_clone.ps1         ← copia o VHD template antes do terraform apply
│   └── lifecycle_check.ps1   ← job diário: shutdown e destroy por TTL
│
└── pipeline/
└── azure-pipelines.yml   ← pipeline principal de criação

5. Variáveis do Ambiente (tfvars)

## O analista preenche um arquivo .tfvars para cada ambiente solicitado. O template abaixo cobre todos os cenários:

# terraform.tfvars — preenchido pelo analista com base no ticket

# Identificação
dev_name           = "joao"             # nome do desenvolvedor
app_name           = "portal"            # identificador da aplicação
app_stack          = "dotnet"            # php | dotnet | angular | moodle

# Repositório
ado_org            = "minha-org"
ado_project        = "Portal"
ado_repo           = "portal-api"
branch             = "develop"

# Banco de Dados
db_server_internal = "db-interno.dominio.local"
db_source          = "portal_homolog"    # banco de homolog a ser clonado
db_name_dev        = "dev_joao_portal"   # nome do novo banco

## # VM
hyperv_host        = "hyperv01.dominio.local"
vm_template_vhd    = "C:\Templates\template-dotnet.vhdx"
vm_cpu             = 2
vm_memory_mb       = 4096
dev_vswitch        = "vSwitch-Dev"

# Acesso Externo (opcional)
external_access      = true              # false = somente acesso interno
app_internal_port    = "443"             # porta da aplicação dentro da VM
fortinet_external_ip = "200.x.x.x"      # IP público do FortiGate
assigned_port        = 8443              # porta externa atribuída ao ambiente
hosted_zone_id       = "Z0XXXXXXXXX"

# Lifecycle
shutdown_date      = "2025-06-01"        # VM desligada nesta data
destroy_date       = "2025-06-08"        # VM e banco removidos nesta data



6. Execução — Passo a Passo

6.1 Preparação (Analista)
Ler o ticket e identificar: desenvolvedor, aplicação, stack, branch, necessidade de acesso externo e prazo.
Duplicar o arquivo terraform.tfvars.tmpl e preencher com os dados do ticket.
Para ambientes com acesso externo: verificar a próxima porta disponível no range reservado (8400–8499) consultando o state ou o arquivo de controle de portas.
Fazer commit do arquivo .tfvars em uma branch separada (nunca na main — pode conter dados sensíveis ou usar variáveis protegidas no pipeline).

6.2 Execução do Pipeline (Azure DevOps)
Acessar o repositório infra-dev-environments no Azure DevOps.
Navegar em Pipelines → infra-dev-create → Run Pipeline.
Selecionar a branch com o arquivo .tfvars preenchido.
Preencher os parâmetros do pipeline (ou confirmar os valores do tfvars).
## Clicar em Run e acompanhar os estágios:
Stage 1 — Clone VHD: copia o template VHD para o disco de destino.
Stage 2 — Terraform Init/Plan: inicializa o backend e exibe o plano de execução.
Stage 3 — Terraform Apply: cria VM, banco, DNS e regras de firewall.
Stage 4 — DB Restore: executa o dump do banco de homolog e restaura com novo nome.
Stage 5 — Ansible: configura stack, cria usuário, clona repositório e configura aplicação.
Stage 6 — Notificação: envia resumo ao analista com URL, credenciais e datas de lifecycle.

6.3 Terraform — Principais Recursos Criados
# VM no Hyper-V
resource "hyperv_machine_instance" "dev_vm" {
name             = "dev-${var.dev_name}-${var.app_name}"
processor_count  = var.vm_cpu
static_memory_mb = var.vm_memory_mb
generation       = 2
hard_disk_drives {
path = "C:\Hyper-V\VHDs\dev-${var.dev_name}-${var.app_name}.vhdx"
}
network_adaptors {
name        = "Ethernet"
switch_name = var.dev_vswitch
}
}

# DNS Interno (PowerShell/Ansible — sem provider nativo)
# Executado via null_resource + remote-exec no host DNS

# Route 53 (somente se external_access = true)
resource "aws_route53_record" "dev_dns" {
count   = var.external_access ? 1 : 0
zone_id = var.hosted_zone_id
name    = "${var.dev_name}.${var.app_name}.dominio.com.br"
type    = "A"
ttl     = 300
records = [var.fortinet_external_ip]
}

# VIP no Fortinet (somente se external_access = true)
resource "fortios_firewall_vip" "dev_vip" {
count       = var.external_access ? 1 : 0
name        = "vip-dev-${var.dev_name}-${var.app_name}"
extip       = var.fortinet_external_ip
extport     = tostring(var.assigned_port)
portforward = "enable"
protocol    = "tcp"
mappedip    { range = local.vm_ip }
mappedport  = var.app_internal_port
}

# Policy no Fortinet (somente se external_access = true)
resource "fortios_firewall_policy" "dev_policy" {
count  = var.external_access ? 1 : 0
name   = "pol-dev-${var.dev_name}-${var.app_name}"
action = "accept"
srcintf { name = "wan" }
dstintf { name = var.dev_vlan_interface }
srcaddr { name = "all" }
dstaddr { name = fortios_firewall_vip.dev_vip[0].name }
service { name = "ALL" }
logtraffic = "all"
}

6.4 Ansible — Playbook Principal
# playbook-dev-setup.yml
- name: Configurar ambiente de desenvolvimento
hosts: "{{ dev_vm_ip }}"
## vars:
dev_user:  "{{ dev_name }}"
app_type:  "{{ app_stack }}"
db_conn:   "{{ db_server_internal }}"
db_name:   "{{ db_name_dev }}"

## roles:
- role: create_user      # cria usuário, senha temporária, força troca no 1º login
- role: deploy_app       # clona repositório do Azure DevOps via PAT
- role: configure_env    # injeta connection string, secrets via Vault
- role: configure_dns_internal  # Add-DnsServerResourceRecordA no servidor DNS
- role: "{{ app_type }}" # role específica: php-fpm, iis+dotnet, node, moodle...


7. Lifecycle dos Ambientes

## Cada ambiente possui duas datas de controle definidas no momento da criação:


## Um job agendado (Task Scheduler no host Hyper-V ou Azure DevOps Scheduled Pipeline) executa diariamente o script de lifecycle:

# lifecycle_check.ps1 — executa diariamente
$today = Get-Date -Format 'yyyy-MM-dd'

foreach ($vm in Get-VM | Where-Object { $_.Notes -ne '' }) {
$meta = $vm.Notes | ConvertFrom-Json

# Notificação 48h antes do shutdown
if ($meta.shutdown_date -eq (Get-Date).AddDays(2).ToString('yyyy-MM-dd')) {
Send-MailMessage -To $meta.dev_email -Subject "Ambiente sera suspenso em 48h" ...
}

# Fase 1: Shutdown
if ($today -eq $meta.shutdown_date -and $vm.State -eq 'Running') {
Stop-VM -Name $vm.Name -Force
Send-MailMessage -To $meta.dev_email -Subject "Ambiente suspenso" ...
}

# Fase 2: Destroy
if ($today -eq $meta.destroy_date) {
# Chama terraform destroy com workspace do ambiente
& terraform -chdir=environments/dev workspace select "$($meta.dev_name)-$($meta.app_name)"
& terraform -chdir=environments/dev destroy -auto-approve
Send-MailMessage -To $meta.dev_email -Subject "Ambiente removido" ...
}
}


8. Segurança e Boas Práticas

8.1 Isolamento de Rede
VMs de dev em uma VLAN/vSwitch dedicado, isolado de produção e homologação.
Regras de firewall no Fortinet restringem o tráfego da VLAN dev.
Banco de dados interno acessível apenas pela VLAN dev (sem acesso direto à internet).

8.2 Credenciais
Todos os segredos (PAT, API tokens, senhas de serviço) armazenados no Azure Key Vault ou HashiCorp Vault.
O pipeline nunca expõe segredos em logs — use variáveis do tipo secret no Azure DevOps.
Desenvolvedor recebe senha temporária; o servidor exige troca no primeiro login.
Credenciais do dev são enviadas via canal seguro (e-mail corporativo ou ticket).

8.3 Dados
O banco de desenvolvimento é uma cópia direta do banco de homologação.
Não deve conter dados de produção — garanta que o banco de homologação também não os contenha.
Considere uma política de retenção: bancos de ambientes destruídos são removidos sem backup.

9. Notificação ao Desenvolvedor

## Ao final da criação, o pipeline envia um resumo ao analista (e opcionalmente ao dev) com todas as informações necessárias:

✅ Ambiente criado com sucesso!

Desenvolvedor : joao
Aplicação     : portal (dotnet / branch: develop)

🖥️  Acesso Interno : http://192.168.100.51
🌍  Acesso Externo : https://joao.portal.dominio.com.br:8443

👤  Usuário        : joao
🔑  Senha inicial  : (entregue via canal seguro)
⚠️  Alterar senha no primeiro login

🗄️  Banco          : dev_joao_portal @ db-interno.dominio.local

📅  Suspensão automática : 01/06/2025
🗑️  Remoção automática   : 08/06/2025

Para renovar o ambiente, abra um ticket de renovação.

10. Referências

Provider Terraform Hyper-V: https://github.com/taliesins/terraform-provider-hyperv
Provider Terraform FortiOS: https://registry.terraform.io/providers/fortinetdev/fortios
Provider Terraform AWS Route 53: https://registry.terraform.io/providers/hashicorp/aws
Ansible Windows: https://docs.ansible.com/ansible/latest/os_guide/windows_usage.html
Azure Pipelines: https://learn.microsoft.com/azure/devops/pipelines
Terraform Backend Azure: https://developer.hashicorp.com/terraform/language/backend/azurerm
