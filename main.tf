terraform {
  required_version = "~> 0.12" 
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

resource "aws_key_pair" "deployer" {
  public_key = var.pubkey
}

resource "aws_kms_key" "kms_key" {
    description  = "Kabu Vault Unseal"
}

resource "aws_kms_alias" "kms_key" {
    name          = "alias/kabu-vault-autounseal"
    target_key_id = aws_kms_key.kms_key.id
}

