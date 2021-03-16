
output "app_list" {
  value = module.bigip[*].app_list_eip
}

output "o01_mgmt_cidrs" {
  value = module.bigip[*].mgmt_cidrs
}

output "o02_pub_cidrs" {
  value = module.bigip[*].pub_cidrs
}

output "o03_priv_cidrs" {
  value = module.bigip[*].priv_cidrs
}

output "o04_all_pub_cidrs" {
  value = module.bigip[*].all_pub_cidrs
}

output "o11_mgmt_ips" {
  value = module.bigip[*].mgmt_ips
}

output "o12_mgmt_pub_ips" {
  value = module.bigip[*].mgmt_pub_ips.public_ip
}

output "o13_pub_ips" {
  value = module.bigip[*].pub_ips
}

output "o14_pub_self_ips_list" {
  value = module.bigip[*].pub_self_ips_list
}

output "o15_pub_vs_ips_list" {
  value = module.bigip[*].pub_vs_ips_list
}

output "o16_priv_ips" {
  value = module.bigip[*].priv_ips
}

output "o17_pub_vs_eips_list" {
  value = module.bigip[*].pub_vs_eips_list
}

output "o21_mgmt_subnet_ids" {
  value = module.bigip[*].mgmt_subnet_ids
}

output "o22_pub_subnet_ids" {
  value = module.bigip[*].pub_subnet_ids
}

output "o23_priv_subnet_ids" {
  value = module.bigip[*].priv_subnet_ids
}

output "o24_pub_and_mgmt_subnet_ids" {
  value = module.bigip[*].pub_and_mgmt_subnet_ids
}

output "o31_f5_password" {
  value = module.bigip[*].f5_password
}

output "o32_app_list_eip_gslb" {
  value = local.cs_dns_module_count > 0 ? module.cs_dns_module[0].app_list_eip_gslb : null
}

output "o33_f5_ssh" {
  value = [
    for index, each_ip in module.bigip[*].mgmt_pub_ips.public_ip :
    format("ssh admin@%s -i ssh-key.pem password: %s", each_ip, module.bigip[index].f5_password)
  ]
}

output "o34_f5_ui" {
  value = [
    for index, each_ip in module.bigip[*].mgmt_pub_ips.public_ip :
    format("https://%s/ password: %s", each_ip, module.bigip[index].f5_password)
  ]
}

# output "o35_as3_declarations_with_certs" {
#   value = local.lets_encrypt_module_count > 0 ? module.lets_encrypt_module[0].as3_declarations : null
# }


output "o36_debug_app_count" {
  value = length(var.app_list)
}

output "o37_app_links" {
  value = [for each_app in var.app_list :
    format("Name: %s , URL: https://%s.%s/", each_app[0], each_app[0], each_app[1])
  ]
}

# output "o38_debug_waf_policy_ids" {
#   value = local.declarative_waf_module_count > 0 ? module.declarative_waf_module[*].waf_policy_ids : null
# }