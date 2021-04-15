locals {
  waf_policy_ids = [
    for each_file in data.local_file.get_waf_policies[*].content : {
      for each_policy in jsondecode(each_file).items :
      element(split("/", each_policy.subPath), 2) => each_policy.id
      if contains(var.app_list[0][0][*][0], element(split("/", each_policy.subPath), 2))
    }
  ]
  suggestion_ids = [
    for each_file in data.local_file.create_export_suggestions[*].content :
    jsondecode(each_file).id != "" ? jsondecode(each_file).id : "NO ID YET"
  ]

  suggestions = [
    for each_file in data.local_file.waf_suggestions[*].content : {
      for each_item in jsondecode(each_file).items :
      each_item.id => each_item.result.suggestions
      if contains(local.suggestion_ids, each_item.id)
    }
  ]
}


resource "null_resource" "get_waf_policies" {
  # This count uses the quantity of bigips
  count = length(var.app_list[0])

  provisioner "local-exec" {
    command = "curl -k -u ${var.f5_user}:${var.f5_pass[count.index]} -H 'Content-type: application/json' https://${var.mgmt_ips[count.index]}/mgmt/tm/asm/policies > ${path.module}/output_files/get_policies_response-${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/get_policies_response-${count.index}.json"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "local_file" "get_waf_policies" {
  # This count uses the quantity of bigips
  count      = length(var.app_list[0])
  depends_on = [null_resource.get_waf_policies]
  filename   = "${path.module}/output_files/get_policies_response-${count.index}.json"
}

resource "local_file" "rendered_export_suggestions" {
  # This count uses the quantity of apps
  count      = var.app_count
  depends_on = [data.local_file.get_waf_policies]
  content = templatefile("${path.module}/templates/export_suggestions.tpl", {
    waf_policy_id = lookup(local.waf_policy_ids[0], var.app_list[0][0][count.index][0], "NO MATCH")
  })
  filename = "${path.module}/output_files/rendered__export_suggestions_${count.index}.json"

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/rendered__export_suggestions_${count.index}.json"
  }
}

resource "null_resource" "create_export_suggestions" {
  # This count uses the quantity of apps
  count      = var.app_count
  depends_on = [local_file.rendered_export_suggestions]

  provisioner "local-exec" {
    command = "curl -k -u ${var.f5_user}:${var.f5_pass[count.index]} -X POST -H 'Content-type: application/json' --data-binary \"@${path.module}/output_files/rendered__export_suggestions_${count.index}.json\" https://${var.mgmt_ips[count.index]}/mgmt/tm/asm/tasks/export-suggestions/ > ${path.module}/output_files/create_export_suggestions_response-${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/create_export_suggestions_response-${count.index}.json"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "local_file" "create_export_suggestions" {
  # This count uses the quantity of apps
  count      = var.app_count
  depends_on = [null_resource.create_export_suggestions]
  filename   = "${path.module}/output_files/create_export_suggestions_response-${count.index}.json"
}


resource "null_resource" "get_export_suggestions" {
  # This count uses the quantity of apps
  count      = var.app_count
  depends_on = [data.local_file.create_export_suggestions]

  provisioner "local-exec" {
    command = "curl -k -u ${var.f5_user}:${var.f5_pass[count.index]} -H 'Content-type: application/json' https://${var.mgmt_ips[count.index]}/mgmt/tm/asm/tasks/export-suggestions/ > ${path.module}/output_files/get_export_suggestions_response-${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/get_export_suggestions_response-${count.index}.json"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "local_file" "waf_policy" {
  depends_on = [null_resource.get_export_suggestions]
  filename   = "${path.module}/templates/waf_policy.tpl"
}

data "local_file" "waf_suggestions" {
  # This count uses the quantity of apps
  count      = var.app_count
  depends_on = [null_resource.get_export_suggestions]
  filename   = "${path.module}/output_files/get_export_suggestions_response-${count.index}.json"
}

resource "local_file" "rendered_policy_with_suggestions" {
  # This count uses the quantity of apps
  count      = var.app_count
  depends_on = [data.local_file.waf_suggestions]
  content = templatefile("${path.module}/templates/waf_parent.tpl", {
    waf_policy        = jsondecode(data.local_file.waf_policy.content)
    waf_modifications = lookup(merge(local.suggestions[0], local.suggestions[1]), local.suggestion_ids[count.index], "NO MATCH")
  })
  filename = "${path.module}/waf_policies/rendered_policy_with_suggestions_${count.index}.json"

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/waf_policies/rendered_policy_with_suggestions_${count.index}.json"
  }
}

data "local_file" "waf_policy_with_suggestions" {
  count      = var.app_count
  depends_on = [local_file.rendered_policy_with_suggestions]
  filename   = "${path.module}/waf_policies/rendered_policy_with_suggestions_${count.index}.json"
}


resource "local_file" "rendered_as3_with_signed_certs" {
  # This count uses the quantity of bigips
  count      = length(var.app_list[0])
  depends_on = [data.local_file.waf_policy_with_suggestions]
  content = templatefile("${path.module}/templates/as3_with_signed_certs.tpl", {
    app_list         = var.app_list[0][count.index]
    waf_enable       = var.waf_enable
    policy_file_name = "rendered_policy_with_suggestions_${count.index}.json"
  })

  filename = "${path.module}/output_files/rendered_as3_with_signed_certs_${count.index}.json"

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/output_files/rendered_as3_with_signed_certs_${count.index}.json"
  }
}


resource "null_resource" "as3_with_with_signed_certs" {
  # This count uses the quantity of bigips
  count      = length(var.app_list[0])
  depends_on = [local_file.rendered_as3_with_signed_certs]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "curl -k -u ${var.f5_user}:${var.f5_pass[count.index]} -X POST -H 'Content-type: application/json' --data-binary \"@${path.module}/output_files/rendered_as3_with_signed_certs_${count.index}.json\" https://${var.mgmt_ips[count.index]}/mgmt/shared/appsvcs/declare"
  }
}
