variable "f5cs_user" {
  description = "provided by parent module"
  default     = {}
  sensitive   = true
}

variable "f5cs_pass" {
  description = "provided by parent module"
  default     = {}
  sensitive   = true
}
variable "f5cs_account_id" {
  description = "provided by parent module"
  default     = ""
  sensitive   = true
}
variable "app_list" {
  description = "provided by parent module"
  default     = {}
}

variable "app_count" {
  description = "provided by parent module"
  default     = ""
}