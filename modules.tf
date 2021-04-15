
module "bigip" {

  source                 = "./bigip_module"
  count                  = local.bigip_count
  max_ip_count_per_nic   = 2
  total_vs_ip_count      = length(var.app_list)
  waf_enable             = true
  dns_enable             = local.bigip_dns_count > 0 ? true : false
  app_list               = var.app_list
  az                     = element(local.azs, count.index)
  cidr                   = "10.0.${count.index}.0/24"
  f5_user                = var.f5_user
  f5_ami_search_name     = var.f5_ami_search_name
  iam_instance_profile   = aws_iam_instance_profile.as3.name
  igw_id                 = module.vpc.igw_id
  prefix                 = "${var.prefix}-${count.index}"
  region                 = var.region
  security_group_mgmt    = aws_security_group.mgmt.id
  security_group_public  = aws_security_group.public.id
  security_group_private = aws_security_group.private.id
  ssh_key_name           = aws_key_pair.demo.key_name
  vpc_id                 = module.vpc.vpc_id
}

module "bigip_dns" {

  source             = "./bigip_dns_module"
  depends_on         = [module.bigip]
  count              = local.bigip_dns_count
  app_list           = module.bigip[*].app_list_eip
  app_count          = length(var.app_list)
  pub_vs_eips_list   = module.bigip[*].pub_vs_eips_list
  pub_mgmt_eips_list = module.bigip[*].pub_mgmt_eips_list
  f5cs_gslb_zone     = var.f5cs_gslb_zone
  f5_user            = var.f5_user
  f5_pass            = module.bigip[*].f5_password
  waf_enable         = false

}

module "cs_dns_module" {
  source           = "./cs_dns_module"
  depends_on       = [module.bigip]
  count            = local.cs_dns_module_count
  f5cs_user        = jsondecode(file(var.f5cs_creds)).f5cs_user
  f5cs_pass        = jsondecode(file(var.f5cs_creds)).f5cs_pass
  f5cs_account_id  = jsondecode(file(var.f5cs_creds)).f5cs_account_id
  app_list         = module.bigip[*].app_list_eip
  app_count        = length(var.app_list)
  pub_vs_eips_list = module.bigip[*].pub_vs_eips_list
  f5cs_gslb_zone   = var.f5cs_gslb_zone
}

module "lets_encrypt_module" {
  source     = "./lets_encrypt_module"
  depends_on = [module.cs_dns_module]
  count      = local.lets_encrypt_module_count
  app_list   = module.cs_dns_module[*].app_list_eip_gslb
  app_count  = length(var.app_list)
  mgmt_ips   = module.bigip[*].mgmt_pub_ips.public_ip
  f5_user    = var.f5_user
  f5_pass    = module.bigip[*].f5_password
  waf_enable = true
}

module "cs_eap_module" {
  source          = "./cs_eap_module"
  depends_on      = [module.lets_encrypt_module]
  count           = local.cs_eap_module_count
  app_list        = module.lets_encrypt_module[*].app_list_eip_gslb_signed_certs
  app_count       = length(var.app_list)
  f5cs_user       = jsondecode(file(var.f5cs_creds)).f5cs_user
  f5cs_pass       = jsondecode(file(var.f5cs_creds)).f5cs_pass
  f5cs_account_id = jsondecode(file(var.f5cs_creds)).f5cs_account_id
}

module "silverline_module" {
  source          = "./silverline_module"
  depends_on      = [module.lets_encrypt_module]
  count           = local.silverline_module_count
  app_list        = module.lets_encrypt_module[*].app_list_eip_gslb_signed_certs
  app_count       = length(var.app_list)
  f5sl_user       = jsondecode(file(var.f5sl_creds)).f5sl_user
  f5sl_pass       = jsondecode(file(var.f5sl_creds)).f5sl_pass
  update_dns      = true
  f5cs_user       = jsondecode(file(var.f5cs_creds)).f5cs_user
  f5cs_pass       = jsondecode(file(var.f5cs_creds)).f5cs_pass
  f5cs_account_id = jsondecode(file(var.f5cs_creds)).f5cs_account_id
}

module "declarative_waf_module" {
  source     = "./declarative_waf_module"
  depends_on = [module.lets_encrypt_module]
  count      = local.declarative_waf_module_count
  app_list   = module.lets_encrypt_module[*].app_list_eip_gslb_signed_certs
  app_count  = length(var.app_list)
  mgmt_ips   = module.bigip[*].mgmt_pub_ips.public_ip
  f5_user    = var.f5_user
  f5_pass    = module.bigip[*].f5_password
  waf_enable = true
}