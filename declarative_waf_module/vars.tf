# variable "f5cs_gslb_zone" {
#   description = "provided by parent module"
#   default = ""
# }

variable "app_list" {
  description = "provided by parent module"
  default = []
}

variable "app_count" {
  description = "provided by parent module"
  default = ""
}

# variable "pub_vs_eips_list" {
#   description = "provided by parent module"
#   default = []
# }

variable "mgmt_ips" {
  description = "provided by parent module"
  default = []
}

variable "f5_user" {
  description = "provided by parent module"
  default = ""
}

variable "f5_pass" {
  description = "provided by parent module"
  default = ""
}

variable "waf_enable" {
    description = "supplied by module parent"
    default     = ""
}