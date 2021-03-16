locals {
  // Determinbes how many BIG-IPs to deploy, across your AZs
  bigip_count = 2
  // The following counts should be set to [0|1] (on/off)
  cs_dns_module_count          = 1
  lets_encrypt_module_count    = 1
  cs_eap_module_count          = 0
  silverline_module_count      = 0
  declarative_waf_module_count = 1

  azs = [
    for each_az in var.azs_short : format("%s%s", var.region, each_az)
  ]
}


variable "region" {
  description = "AWS region name"
  default     = "eu-west-1"
}

variable "azs_short" {
  description = "Assumes three AZs within region.  Locals below will format the full AZ names based on Region"
  default     = ["a", "b", "c"]
}

variable "cidr" {
  description = "cidr used for AWS VPC"
  default     = "10.0.0.0/16"
}

variable "bigip_count" {
  description = "number of BIG-IP instances to deploy"
  default     = "2"
}

variable "f5_ami_search_name" {
  description = "filter used to find AMI for deployment"
  default     = "F5*BIGIP-16.0.1.1*Best*25Mbps*"
}

variable "f5_user" {
  description = "supplied by parent"
  default     = "admin"
}

variable "prefix" {
  description = "prefix used for naming objects created in AWS"
  default     = "arch-tf-modular"
}

variable "uk_se_name" {
  description = "UK SE name tag"
  default     = "arch"
}

variable "f5cs_gslb_zone" {
  description = "F5 Cloud Services Zone"
  default     = "gslb.archf5.com"
}

variable "f5cs_creds" {
  description = "F5 Cloud Services credentials location"
  default     = "../creds/f5cs_creds.json"
  sensitive   = true
}

variable "f5sl_creds" {
  description = "F5 Silverline credentials location"
  default     = "../creds/f5sl_creds.json"
  sensitive   = true
}

variable "waf_enable" {
  description = "Enable ASM Provisioning and policy on BIG-IP"
  default     = true
}