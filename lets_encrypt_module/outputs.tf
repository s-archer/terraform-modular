# output "deployed_app_target_urls" {
#   value = [
#     for each_app in var.app_list[0] :
#     format("For Application '%s' :  https://%s.%s", each_app[0], each_app[0], each_app[1])
#   ]
# }

output "app_list_eip_gslb_signed_certs" {
  value = local.app_list
}

output "as3_declarations" {
  value = local.as3_declarations
}
# output "apps_list_0_length" {
#   value = length(local.app_list[0])
# }

# output "a1-cert-raw" {
#   value = data.local_file.signed_certs[0].content
# }

# output "a2-key-raw" {
#   value = tls_private_key.as3_apps[0].private_key_pem
# }