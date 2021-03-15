output "app_links" {
  value = [for index, each_app in var.app_list[0] :
    format("Name: %s , URL: https://%s.%s/ (CNAME to gslb subdomain: https://%s.%s)", each_app[0], each_app[0], each_app[1], each_app[0], local.gslb_zones[index])
  ]
}

output "app_list_eip_gslb" {
  value = local.app_list
}


# output "pub_vs_eips_list" {
#   value = local.pub_vs_eips_list
# }

# output "z_access_token" {
#   value = jsondecode(data.local_file.f5cs_login_response.content).access_token
# }

# output "z_acc_info" {
#   value = jsondecode(data.local_file.f5cs_acc_info_response.content).id
# }

# output "z_create_info" {
#   value = jsondecode(data.local_file.f5cs5_create_dns_lb.content).subscription_id
# }

# output "z_member_info" {
#   value = [ for mem in jsondecode(data.local_file.f5cs_member_info_response.content).memberships :
#     mem.account_id if mem.account_name == "F5 Cloud Services Demo"
#   ]
# }

# output "z_subs_id" {
#   value = local.dns_subs
# }