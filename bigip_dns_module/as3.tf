resource "local_file" "rendered_as3" {
  # This count uses the quantity of bigips
  count = length(var.app_list[0])
  content = templatefile("${path.module}/templates/as3.tpl", {
    app_list           = var.app_list[count.index]
    app_list_full      = var.app_list
    pub_vs_eips_list = var.pub_vs_eips_list[count.index]
    waf_enable         = var.waf_enable

  })
  filename = "${path.module}/output_files/rendered_as3_${count.index}.json"

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/rendered_as3_${count.index}.json"
  }
}


# resource "null_resource" "as3_with_dns" {
#   count      = var.app_count
#   depends_on = [local_file.rendered_as3]

#   triggers = {
#     always_run = timestamp()
#   }
  
#   provisioner "local-exec" {
#     command = "curl -k -u ${var.f5_user}:${var.f5_pass[count.index]} -X POST -H 'Content-type: application/json' --data-binary \"@${path.module}/output_files/rendered_as3_${count.index}.json\" https://${var.pub_mgmt_eips_list[count.index][0].public_ip}/mgmt/shared/appsvcs/declare"
#   }
# }