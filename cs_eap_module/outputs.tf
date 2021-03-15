# output "z_app_links" {
#   value = [for index, each_app in var.app_list[0] :
#     format("Name: %s , URL: https://%s.%s/ (CNAME to gslb subdomain: https://%s.%s)", each_app[0], each_app[0], each_app[1], each_app[0], local.gslb_zones[index])
#   ]
# }

# output "debug" {
#   value = "cert = ${local.cert_only[0]}, chain = ${local.chain_only[0]}"
# }