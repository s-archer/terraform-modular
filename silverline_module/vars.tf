variable "silverline_login_url" {
  default = "https://portal.f5silverline.com/api/v1/sessions"
}

variable "silverline_proxies_url" {
  default = "https://portal.f5silverline.com/api/v1/proxies"
}

variable "silverline_front_end_profile_url" {
  default = "https://portal.f5silverline.com/api/v1/ssl/front_end_profiles/"
}

variable "silverline_certs_url" {
  default = "https://portal.f5silverline.com/api/v1/ssl/cert_keys/"
}

variable "f5sl_user" {
  description = "provided by parent module"
  sensitive   = true
  default     = ""
}

variable "f5sl_pass" {
  description = "provided by parent module"
  sensitive   = true
  default     = ""
}

variable "app_list" {
  description = "provided by parent module"
  default     = {}
}

variable "app_count" {
  description = "provided by parent module"
  default     = ""
}

variable "update_dns" {
  description = "provided by parent module"
  default     = ""
}

variable "f5cs_user" {
  description = "provided by parent module"
  sensitive   = true
  default     = ""
}

variable "f5cs_pass" {
  description = "provided by parent module"
  sensitive   = true
  default     = ""
}
variable "f5cs_account_id" {
  description = "provided by parent module"
  default     = ""
  sensitive   = true
}