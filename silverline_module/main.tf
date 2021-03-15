locals {
  token = jsondecode(data.local_file.login_response.content).data.attributes.auth_token
  frontend_ip = [for each_response in data.local_file.create_proxy_response :
    jsondecode(each_response.content).data.attributes.frontend_ip
  ]
}


#  Template file JSON body for API POST request to login to Silverline to get token
data "template_file" "login" {
  template = file("${path.module}/templates/login.tpl")

  vars = {
    f5sl_user = var.f5sl_user,
    f5sl_pass = var.f5sl_pass
  }
}

#  API POST request to login to Silverline to get token.  Output is written to file (not secure), but there is currenlty no other option with Terraform until either:
#    - terraform external data source allows muli-level json query, or...
#    - terraform http data source allows POST (currently only GET is allowed), or...
#    - f5 create a Silverline Terraform Provider
resource "null_resource" "login" {

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' --data-raw '${data.template_file.login.rendered}' ${var.silverline_login_url} > ${path.module}/output_files/f5sl1_login_response.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5sl1_login_response.json"
  }
}

#  Open the login_response file
data "local_file" "login_response" {
  filename   = "${path.module}/output_files/f5sl1_login_response.json"
  depends_on = [null_resource.login]
}


# Get a list of proxies using the token in the X-Authorization-Token header.  Write output to get_proxies_response.json file.
# resource "null_resource" "get_proxies" {

#   provisioner "local-exec" {
#     command = "curl -k -X GET -H 'Content-type: application/json' -H 'X-Authorization-Token: ${local.token}' ${var.silverline_proxies_url} > ${path.module}/output_files/f5sl2_get_proxies_response.json"
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = "rm -f ${path.module}/output_files/f5sl2_get_proxies_response.json"
#   }
# }

resource "local_file" "rendered_sl_certs" {
  count      = var.app_count
  depends_on = [data.local_file.login_response]
  content = templatefile("${path.module}/templates/create_certs_json.tpl", {
    app_name    = var.app_list[0][0][count.index][0]
    domain      = var.app_list[0][0][count.index][1]
    certificate = var.app_list[0][0][count.index][2]
    key         = var.app_list[0][0][count.index][3]
    chain       = var.app_list[0][0][count.index][9]
  })
  filename = "${path.module}/output_files/f5sl3_rendered_create_certs_${count.index}.json"
}


resource "null_resource" "create_certs" {
  count      = var.app_count
  depends_on = [local_file.rendered_sl_certs]

  provisioner "local-exec" {
    command = "curl --location --request POST -H 'Content-type: application/json' -H 'X-Authorization-Token: ${local.token}' --data-binary '@${path.module}/output_files/f5sl3_rendered_create_certs_${count.index}.json' ${var.silverline_certs_url} > ${path.module}/output_files/f5sl4_create_certs_response_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5sl4_create_certs_response_${count.index}.json"
  }
}


resource "local_file" "rendered_sl_front_end" {
  count      = var.app_count
  depends_on = [null_resource.create_certs]
  content = templatefile("${path.module}/templates/create_front_end_json.tpl", {
    app_name = var.app_list[0][0][count.index][0]
    domain   = var.app_list[0][0][count.index][1]
  })
  filename = "${path.module}/output_files/f5sl5_rendered_create_front_end_${count.index}.json"
}


resource "null_resource" "create_front_end" {
  count      = var.app_count
  depends_on = [local_file.rendered_sl_front_end]

  provisioner "local-exec" {
    command = "curl -v --location --request POST -H 'Content-type: application/json' -H 'X-Authorization-Token: ${local.token}' --data-binary '@${path.module}/output_files/f5sl5_rendered_create_front_end_${count.index}.json' ${var.silverline_front_end_profile_url} > ${path.module}/output_files/f5sl6_create_front_end_response_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5sl6_create_front_end_response_${count.index}.json"
  }
}


resource "local_file" "rendered_sl_proxy" {
  count      = var.app_count
  depends_on = [null_resource.create_front_end]
  content = templatefile("${path.module}/templates/create_proxy_json.tpl", {
    app_name  = var.app_list[0][0][count.index][0]
    gslb_fqdn = var.app_list[0][0][count.index][8]
    domain    = var.app_list[0][0][count.index][1]
  })
  filename = "${path.module}/output_files/f5sl7_rendered_create_proxy_${count.index}.json"
}


# # # Create a new Silverline proxy with API POST..
resource "null_resource" "create_proxy" {
  count      = var.app_count
  depends_on = [local_file.rendered_sl_proxy]

  provisioner "local-exec" {
    command = "sleep 20; curl --location --request POST -H 'Content-type: application/json' -H 'X-Authorization-Token: ${local.token}' --data-binary '@${path.module}/output_files/f5sl7_rendered_create_proxy_${count.index}.json' ${var.silverline_proxies_url} > ${path.module}/output_files/f5sl8_create_proxy_response_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5sl8_create_proxy_response_${count.index}.json"
  }
}


#  Open the proxy create response file
data "local_file" "create_proxy_response" {
  count      = var.app_count
  filename   = "${path.module}/output_files/f5sl8_create_proxy_response_${count.index}.json"
  depends_on = [null_resource.create_proxy]
}


# Deploy the proxy to production
resource "null_resource" "deploy_proxy" {
  count      = var.app_count
  depends_on = [data.local_file.create_proxy_response]

  provisioner "local-exec" {
    command = "curl --location --request POST -H 'Content-type: application/json' -H 'X-Authorization-Token: ${local.token}' --data-binary '@${path.module}/templates/deploy_proxy_json.tpl' ${var.silverline_proxies_url}/${jsondecode(data.local_file.create_proxy_response[count.index].content).data.id}/deployments > ${path.module}/output_files/f5sl9_deploy_proxy_response_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5sl9_deploy_proxy_response_${count.index}.json"
  }
}