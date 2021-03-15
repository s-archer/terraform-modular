#  Output the create proxy response for testing
# output "debug" {
#   value = jsondecode(data.local_file.create_proxy_response[0].content).data.id 
# }

#  Output vars for testing
output "debug1" {
  value = var.app_list[0]
}
output "debug2" {
  value = local.frontend_ip
}
