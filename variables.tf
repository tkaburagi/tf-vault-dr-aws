variable "access_key" {}
variable "secret_key" {}
variable "pubkey" {}
variable "ssh_private_key" {}
variable "dns_zone_id" {}

variable "domain" {
    default = "hashidemos.io"
}

variable "vault_dr0_fqdn" {
    default = "vault-dr-0.kabu.hashidemos.io"
}

variable "vault_dr1_fqdn" {
    default = "vault-dr-1.kabu.hashidemos.io"
}

variable "num_of_site" {
    default = 2
}

variable "vault_instance_count" {
    default = 2
}

variable "region" {
    default = "ap-northeast-1"
}

variable "vault_instance_type" {
    default = "t2.large"
}

variable "availability_zones" {
    type = "list"
    default = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "vpc_cidr" {
    default = "10.10.0.0/16"
}

variable "subnets_cidr" {
    type = "list"
    default = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "private_ips" {
    type = "list"
    default = ["10.10.0.50","10.10.1.50"]
}

variable "public_subnet_name" {
    default = "public"
}

variable "ami" {
    default = "ami-06d9ad3f86032262d"
}

variable "vault_instance_name" {
    default = "dr-vault"
}

variable "tags" {
    type        = "map"
    default     = {}
    description = "Key/value tags to assign to all AWS resources"
}

variable "vault_dl_url" {
    default = "https://releases.hashicorp.com/vault/1.4.2+ent/vault_1.4.2+ent_linux_amd64.zip"
}