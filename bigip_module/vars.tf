variable "total_vs_ip_count" {
  description = "supplied by module parent"
  default     = ""
}

variable "max_ip_count_per_nic" {
  description = "supplied by module parent"
  default     = ""
}

variable "f5_ami_search_name" {
  description = "supplied by module parent"
  default     = ""
}

variable "f5_user" {
  description = "supplied by module parent"
  default     = ""
}

variable "igw_id" {
  description = "supplied by module parent"
  default     = ""
}

variable "region" {
  description = "supplied by module parent"
  default     = ""
}

variable "vpc_id" {
  description = "supplied by module parent"
  default     = ""
}

variable "az" {
  description = "supplied by module parent"
  default     = ""
}

variable "cidr" {
  description = "supplied by module parent"
  default     = ""
}

variable "prefix" {
  description = "supplied by module parent"
  default     = ""
}

variable "security_group_mgmt" {
  description = "supplied by module parent"
  default     = ""
}

variable "security_group_public" {
  description = "supplied by module parent"
  default     = ""
}

variable "security_group_private" {
  description = "supplied by module parent"
  default     = ""
}

variable "ssh_key_name" {
  description = "supplied by module parent"
  default     = ""
}

variable "iam_instance_profile" {
  description = "supplied by module parent"
  default     = ""
}

variable "app_list" {
    description = "supplied by module parent"
    default     = []
}
variable "waf_enable" {
    description = "supplied by module parent"
    default     = ""
}