resource "local_file" "rendered_as3" {
  content = templatefile("${path.module}/templates/as3.tpl", {
    #vip = local.pub_vs_eips_list[0].private_ip
    app_list = local.app_list
    waf_enable   = var.waf_enable
  })
  filename = "${path.module}/output_files/${var.prefix}-rendered_as3.json"
}

resource "null_resource" "as3_app_list" {
  depends_on = [aws_instance.f5]
  provisioner "local-exec" {
    command = "curl -k -u ${var.f5_user}:${random_string.password.result} -X POST -H 'Content-type: application/json' --data-binary \"@${path.module}/output_files/${var.prefix}-rendered_as3.json\" https://${aws_eip.f5-mgmt.public_ip}/mgmt/shared/appsvcs/declare"
  }
}

# resource "null_resource" "fast_app" {
#   provisioner "local-exec" {
#     command = "curl -k -u ${var.f5_user}:${random_string.password.result} -X POST -H 'Content-type: application/json' --data-raw '${path.module}/output_files/${var.prefix}-rendered_as3.json' https:///mgmt/shared/appsvcs/declare"
#   }
# }

