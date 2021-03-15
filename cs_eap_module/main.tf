locals {
  #Parse the subs list to find the subscription for the parent DNS zone.
  dns_subs = [for subs in jsondecode(data.local_file.f5cs_get_subs_list_response.content).subscriptions :
    subs.subscription_id if subs.service_instance_name == "archf5.com"
  ]

  # mem_acc_id = [for mem in jsondecode(data.local_file.f5cs_member_info_response.content).memberships :
  #   mem.account_id if mem.account_name == "F5 Cloud Services Demo"
  # ]

  eap_subs_id = [for each_response in data.local_file.cs_create_eap :
    jsondecode(each_response.content).subscription_id
  ]
  eap_subs_cname = [for each_response in data.local_file.cs_get_subs_cname :
    jsondecode(each_response.content).configuration.details.CNAMEValue
  ]

}


resource "null_resource" "cs_login" {

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' --data-raw '{ \"username\": \"${var.f5cs_user}\",\"password\": \"${var.f5cs_pass}\" }' https://api.cloudservices.f5.com/v1/svc-auth/login > ${path.module}/output_files/f5cs1_login_response.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5cs1_login_response.json"
  }
}


data "local_file" "f5cs_login_response" {
  filename   = "${path.module}/output_files/f5cs1_login_response.json"
  depends_on = [null_resource.cs_login]
}


# resource "null_resource" "cs_acc_info" {

#   provisioner "local-exec" {
#     command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-account/user > ${path.module}/output_files/f5cs2_acc_info.json"
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = "rm -f ${path.module}/output_files/f5cs2_acc_info.json"
#   }
# }


# data "local_file" "f5cs_acc_info_response" {
#   filename   = "${path.module}/output_files/f5cs2_acc_info.json"
#   depends_on = [null_resource.cs_acc_info]
# }


# resource "null_resource" "cs_member_info" {

#   provisioner "local-exec" {
#     command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-account/users/${jsondecode(data.local_file.f5cs_acc_info_response.content).id}/memberships > ${path.module}/output_files/f5cs3_member_info.json"
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = "rm -f ${path.module}/output_files/f5cs3_member_info.json"
#   }
# }


# data "local_file" "f5cs_member_info_response" {
#   filename   = "${path.module}/output_files/f5cs3_member_info.json"
#   depends_on = [null_resource.cs_member_info]
# }


resource "local_file" "rendered_cs_certs" {
  count      = var.app_count
  #depends_on = [data.local_file.f5cs_member_info_response]
  depends_on = [data.local_file.f5cs_login_response]
  content = templatefile("${path.module}/templates/cs_add_cert.tpl", {
    certificate = var.app_list[0][0][count.index][2]
    key         = var.app_list[0][0][count.index][3]
    chain       = var.app_list[0][0][count.index][9]
    #account_id  = local.mem_acc_id[0]
    account_id  = var.f5cs_account_id
  })
  filename = "${path.module}/output_files/f5cs4_rendered_cs_add_cert_${count.index}.json"
}


resource "null_resource" "cs_create_certs" {
  count      = var.app_count
  depends_on = [local_file.rendered_cs_certs]

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' --data-binary '@${path.module}/output_files/f5cs4_rendered_cs_add_cert_${count.index}.json' https://api.cloudservices.f5.com/v1/svc-certificates/certificates > ${path.module}/output_files/f5cs5_create_certs_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5cs5_create_certs_${count.index}.json"
  }
}


data "local_file" "f5cs5_create_certs" {
  count      = var.app_count
  filename   = "${path.module}/output_files/f5cs5_create_certs_${count.index}.json"
  depends_on = [null_resource.cs_create_certs]
}


resource "local_file" "rendered_cs_eap" {
  count      = var.app_count
  depends_on = [data.local_file.f5cs5_create_certs]
  content = templatefile("${path.module}/templates/cs_eap.tpl", {
    certificate_id = jsondecode(data.local_file.f5cs5_create_certs[count.index].content).id
    fqdn           = format("%s.%s", var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])
    gslb_name      = var.app_list[0][0][count.index][8]
    app_name       = var.app_list[0][0][count.index][0]
    #account_id  = local.mem_acc_id[0]
    account_id  = var.f5cs_account_id
  })
  filename = "${path.module}/output_files/f5cs6_rendered_cs_eap_${count.index}.json"
}


resource "null_resource" "cs_create_eap" {
  count      = var.app_count
  depends_on = [local_file.rendered_cs_eap]

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' --data-binary '@${path.module}/output_files/f5cs6_rendered_cs_eap_${count.index}.json' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions > ${path.module}/output_files/f5cs7_create_eap_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5cs7_create_eap_${count.index}.json"
  }
}


data "local_file" "cs_create_eap" {
  count      = var.app_count
  filename   = "${path.module}/output_files/f5cs7_create_eap_${count.index}.json"
  depends_on = [null_resource.cs_create_eap]
}


resource "null_resource" "cs_activate_eap" {
  count      = var.app_count
  depends_on = [local_file.rendered_cs_eap]

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions/${local.eap_subs_id[count.index]}/activate > ${path.module}/output_files/f5cs8_activate_eap_${count.index}.json"
  }

  # This provisioner runs a 'while' loop until EAP is in the DEPLOYED state.
  provisioner "local-exec" {
    command = "while [[ \"$(curl -ski -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions/${local.eap_subs_id[count.index]}/status | grep -Eoh \"DEPLOYED\")\" != \"DEPLOYED\" ]]; do sleep 5; done"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5cs8_activate_eap_${count.index}.json"
  }
}


resource "null_resource" "cs_get_subs_cname" {
  count      = var.app_count
  depends_on = [null_resource.cs_activate_eap]

  provisioner "local-exec" {
    command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions/${local.eap_subs_id[count.index]} > ${path.module}/output_files/f5cs9_get_subs_cname_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5cs9_get_subs_cname_${count.index}.json"
  }
}

data "local_file" "cs_get_subs_cname" {
  count      = var.app_count
  filename   = "${path.module}/output_files/f5cs9_get_subs_cname_${count.index}.json"
  depends_on = [null_resource.cs_get_subs_cname]
}


resource "local_file" "rendered_cs_eap_cname" {
  depends_on = [data.local_file.cs_get_subs_cname]
  content = templatefile("${path.module}/templates/cs_dns_cname.tpl", {
    a_records     = var.app_list[0][0]
    eap_waf_cname = local.eap_subs_cname
  })
  filename = "${path.module}/output_files/f5cs10_rendered_cs_eap_cname.json"
}


resource "null_resource" "cs_find_dns_subscription" {
  depends_on = [local_file.rendered_cs_eap_cname]

  provisioner "local-exec" {
    #command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions?account_id=${local.mem_acc_id[0]} > ${path.module}/output_files/f5cs11_get_subs_list.json"
    command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions?account_id=${var.f5cs_account_id} > ${path.module}/output_files/f5cs11_get_subs_list.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5cs11_get_subs_list.json"
  }
}


data "local_file" "f5cs_get_subs_list_response" {
  filename   = "${path.module}/output_files/f5cs11_get_subs_list.json"
  depends_on = [null_resource.cs_find_dns_subscription]
}


resource "null_resource" "cs_modify_eap_cname_in_parent_zone" {
  depends_on = [data.local_file.f5cs_get_subs_list_response]

  provisioner "local-exec" {
    command = "curl -k -X PUT -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' --data-binary '@${path.module}/output_files/f5cs10_rendered_cs_eap_cname.json' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions/${local.dns_subs[0]} > ${path.module}/output_files/f5cs12_modify_eap_cname_in_parent_zone_response.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/f5cs12_modify_eap_cname_in_parent_zone_response.json"
  }
}