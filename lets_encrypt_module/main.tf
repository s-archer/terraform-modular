locals {

  cert_list = [
    for each_cert_chain in data.local_file.signed_certs : [
      regexall("(-----BEGIN CERTIFICATE-----[\\s\\S]*?-----END CERTIFICATE-----)", each_cert_chain.content)[0]
    ]
  ]

  chain_list = [
    for each_cert_chain in data.local_file.signed_certs : [
      regexall("(-----BEGIN CERTIFICATE-----[\\s\\S]*?-----END CERTIFICATE-----)", each_cert_chain.content)[1]
    ]
  ]

  key_list = [
    for each_key in data.local_file.as3_demo_private_key : [
      each_key.content
    ]
  ]

  as3_declarations = [  
    for index, each_bigip in var.app_list[0] : [
      templatefile("${path.module}/templates/as3_with_signed_certs.tpl", { app_list = var.app_list[0][index], challenge_data = data.local_file.challenge[*].content, private_key = tls_private_key.as3_apps[*].private_key_pem, certificate = data.local_file.signed_certs[*].content, waf_enable = var.waf_enable})
    ]
  ]

  app_list = [
    for each_bigip in var.app_list[0] : [
      for index, each_app in each_bigip : flatten(concat([each_app[0]], [each_app[1]], [local.cert_list[index][0]], [local.key_list[index][0]], [each_app[4]], [each_app[5]], [each_app[6]], [each_app[7]], [each_app[8]], [local.chain_list[index][0]]))
    ]
  ]
}

resource "tls_private_key" "lets_encrypt_account_key" {
  algorithm = "RSA"
}

resource "tls_private_key" "as3_apps" {
  # This count uses the quantity of apps on bigip[0] (same qty as on bigip[1])
  count     = var.app_count
  algorithm = "RSA"
}

resource "local_file" "as3_demo_private_key" {
  count    = var.app_count
  content  = tls_private_key.as3_apps[count.index].private_key_pem
  filename = format("%s/certificates/key-%s%s.pem", path.module, var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])

  provisioner "local-exec" {
    when    = destroy
    command = format("rm -f %s/certificates/key-*.pem", path.module)
  }
}

data "local_file" "as3_demo_private_key" {
  count      = var.app_count
  depends_on = [local_file.as3_demo_private_key]
  filename   = format("%s/certificates/key-%s%s.pem", path.module, var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])
}

resource "tls_cert_request" "as3_demo_csr" {
  count           = var.app_count
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.as3_apps[count.index].private_key_pem

  subject {
    common_name  = format("%s.%s", var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])
    organization = "Arch Demo Environment"
  }
}

resource "local_file" "as3_demo_csr" {
  count    = var.app_count
  content  = tls_cert_request.as3_demo_csr[count.index].cert_request_pem
  filename = format("%s/certificates/csr-%s%s.pem", path.module, var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])

  provisioner "local-exec" {
    when    = destroy
    command = format("rm -f %s/certificates/csr-*.pem", path.module)
  }
}

resource "null_resource" "acme_get_challenge" {
  count      = var.app_count
  depends_on = [local_file.as3_demo_csr]

  provisioner "local-exec" {
    command = "python ${path.module}/scripts/acme_tiny_prep_challenge.py --account-key ${path.module}/certificates/letsencrypt_account.pem.key --csr ${format("%s/certificates/csr-%s%s.pem", path.module, var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])} > ${format("%s/output_files/challenge_content-%s%s.txt", path.module, var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = format("rm -f %s/output_files/challenge_content-*.txt", path.module)
  }
}

data "local_file" "challenge" {
  count      = var.app_count
  depends_on = [null_resource.acme_get_challenge]
  filename   = format("%s/output_files/challenge_content-%s%s.txt", path.module, var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])
}

resource "local_file" "rendered_as3_with_challenge_iRule" {
  # This count uses the quantity of bigips
  count = var.app_count
  content = templatefile("${path.module}/templates/as3_challenge.tpl", {
    app_list       = var.app_list[0][count.index]
    challenge_data = data.local_file.challenge[*].content
    waf_enable     = var.waf_enable
  })
  filename = "${path.module}/output_files/rendered_as3_with_iRule_${count.index}.json"

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/rendered_as3_with_iRule_${count.index}.json"
  }
}

resource "null_resource" "as3_with_iRule" {
  count      = var.app_count
  depends_on = [local_file.rendered_as3_with_challenge_iRule]

  provisioner "local-exec" {
    command = "curl -k -u ${var.f5_user}:${var.f5_pass[count.index]} -X POST -H 'Content-type: application/json' --data-binary \"@${path.module}/output_files/rendered_as3_with_iRule_${count.index}.json\" https://${var.mgmt_ips[count.index]}/mgmt/shared/appsvcs/declare"
  }

  provisioner "local-exec" {
    command = "while [[ \"$(curl -si http://${format("%s.%s", var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])}/.well-known/acme-challenge/ | grep -Eoh \"${data.local_file.challenge[count.index].content}\")\" != \"${data.local_file.challenge[count.index].content}\" ]]; do sleep 5; done"
  }
}

resource "null_resource" "acme_get_cert" {
  count      = var.app_count
  depends_on = [null_resource.as3_with_iRule]

  provisioner "local-exec" {
    command = "python ${path.module}/scripts/acme_tiny_get_cert.py --account-key ${path.module}/certificates/letsencrypt_account.pem.key --csr ${format("%s/certificates/csr-%s%s.pem", path.module, var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])} > ${format("%s/certificates/signed_crt-%s%s.pem", path.module, var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/certificates/signed_crt-*.pem"
  }
}

data "local_file" "signed_certs" {
  count      = var.app_count
  depends_on = [null_resource.acme_get_cert]
  filename   = format("%s/certificates/signed_crt-%s%s.pem", path.module, var.app_list[0][0][count.index][0], var.app_list[0][0][count.index][1])
}

resource "local_file" "rendered_as3_with_signed_certs" {
  # This count uses the quantity of bigips
  count = var.app_count
  content = templatefile("${path.module}/templates/as3_with_signed_certs.tpl", {
    app_list       = var.app_list[0][count.index]
    challenge_data = data.local_file.challenge[*].content
    private_key    = tls_private_key.as3_apps[*].private_key_pem
    certificate    = data.local_file.signed_certs[*].content
    waf_enable     = var.waf_enable
  })
  filename = "${path.module}/output_files/rendered_as3_with_signed_certs_${count.index}.json"

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/rendered_as3_with_signed_certs_${count.index}.json"
  }
}


resource "null_resource" "as3_with_with_signed_certs" {
  count      = var.app_count
  depends_on = [local_file.rendered_as3_with_signed_certs]

  provisioner "local-exec" {
    command = "curl -k -u ${var.f5_user}:${var.f5_pass[count.index]} -X POST -H 'Content-type: application/json' --data-binary \"@${path.module}/output_files/rendered_as3_with_signed_certs_${count.index}.json\" https://${var.mgmt_ips[count.index]}/mgmt/shared/appsvcs/declare"
  }
}