terraform {
  required_version = ">= 1.6.0"

  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 1.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    fortios = {
      source  = "fortinetdev/fortios"
      version = "~> 1.21"
    }
  }

  # TODO_MANUAL: escolher e configurar backend remoto (s3 ou azurerm)
  # backend "s3" {}
}

provider "hyperv" {
  host     = var.hyperv_host
  username = var.hyperv_username
  password = var.hyperv_password
  https    = true
}

provider "aws" {
  region = var.aws_region
}

provider "fortios" {
  hostname = var.fortinet_hostname
  token    = var.fortinet_api_token
  insecure = false
}
