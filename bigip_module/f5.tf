
resource "random_string" "password" {
  length  = 10
  special = false
}

data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = [var.f5_ami_search_name]
  }
}

# MGMT INTERFACE ---------------
resource "aws_network_interface" "f5-mgmt" {
  subnet_id       = local.mgmt_subnet_ids
  security_groups = [var.security_group_mgmt]
  private_ips     = local.mgmt_ips[local.mgmt_cidrs[0]]

  tags = {
    Name = "${var.prefix}-mgmt_interface"
  }
}

resource "aws_eip" "f5-mgmt" {
  network_interface         = aws_network_interface.f5-mgmt.id
  associate_with_private_ip = local.mgmt_ips[local.mgmt_cidrs[0]][0]
  vpc                       = true

  tags = {
    Name = "${var.prefix}-mgmt"
  }
}

# # EXT INTERFACE ----------------

resource "aws_network_interface" "f5-pub" {
  count           = length(local.pub_subnet_ids)
  subnet_id       = local.pub_subnet_ids[count.index]
  security_groups = [var.security_group_public]
  private_ips     = local.pub_ips[local.pub_cidrs[count.index]]

  tags = {
    Name = "${var.prefix}-public_interface"
  }
}

resource "aws_eip" "f5-pub" {
  count                     = length(local.pub_vs_ips_list)
  network_interface         = aws_network_interface.f5-pub[(ceil((count.index +1) / (var.max_ip_count_per_nic -1)) -1)].id
  associate_with_private_ip = element((split("/", local.pub_vs_ips_list[count.index])),0)
  vpc                       = true

  tags = {
    Name    = "${var.prefix}-1-pub-[count.index]"
    priv_ip = local.pub_ips_list[count.index]
  }
}


# # INT INTERFACE ----------------

resource "aws_network_interface" "f5-priv" {
  subnet_id       = local.priv_subnet_ids
  security_groups = [var.security_group_private]
  private_ips     = [element(split("/", local.priv_ips[0]), 0)]

  tags = {
    Name = "${var.prefix}-priv_interface"
  }
}

# # ONBOARDING TEMPLATE  ---------

# write declaration out to local file for debug
resource "local_file" "do" {
  content       = templatefile("${path.module}/templates/do.tpl", {
    hostname     = aws_eip.f5-mgmt.public_dns,
    admin_pass   = random_string.password.result,
    external_ips = local.pub_self_ips_list,
    internal_ip  = local.priv_ips[0],
    internal_gw  = cidrhost(local.priv_cidrs[0], 1),
    cidr         = "10.0.0.0/16"
    waf_enable   = var.waf_enable
  })
  filename = "${path.module}/output_files/${var.prefix}-rendered_do.json"
}

data "template_file" "do" {
  template = templatefile("${path.module}/templates/do.tpl", {
    hostname     = aws_eip.f5-mgmt.public_dns,
    admin_pass   = random_string.password.result,
    external_ips = local.pub_self_ips_list,
    internal_ip  = local.priv_ips[0],
    internal_gw  = cidrhost(local.priv_cidrs[0], 1),
    cidr         = "10.0.0.0/16"
    waf_enable   = var.waf_enable
  })
}

data "template_file" "f5_onboard" {
  template = file("${path.module}/templates/user_data_json.tpl")
  
  vars = {
    do_declaration = data.template_file.do.rendered
  }
}

# # AMI INSTANCE ----------------

resource "aws_instance" "f5" {

  ami                  = data.aws_ami.f5_ami.id
  instance_type        = "m4.4xlarge"
  user_data            = data.template_file.f5_onboard.rendered
  key_name             = var.ssh_key_name
  iam_instance_profile = var.iam_instance_profile

  network_interface {
    network_interface_id = aws_network_interface.f5-mgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.f5-priv.id
    device_index         = 1
  }

  dynamic "network_interface" {
    for_each = aws_network_interface.f5-pub
    content {
      network_interface_id = network_interface.value.id
      device_index         = (network_interface.key + 2)
    }
  }

  provisioner "local-exec" {
    command = "while [[ \"$(curl -skiu ${var.f5_user}:${random_string.password.result} https://${self.public_ip}/mgmt/shared/appsvcs/declare | grep -Eoh \"^HTTP/1.1 204\")\" != \"HTTP/1.1 204\" ]]; do sleep 5; done"
  }
  
  # If WAF is enabled, check that WAF is up, or if WAF is disabled, just return true, so provisioner succeeds.
  provisioner "local-exec" {
    command = var.waf_enable == true ? "while [[ \"$(curl -skiu ${var.f5_user}:${random_string.password.result} https://${self.public_ip}/mgmt/tm/asm/health-alerts | grep -Eoh \"^HTTP/1.1 200\")\" != \"HTTP/1.1 200\" ]]; do sleep 5; done" : "true"
  }

  tags = {
    Name  = "${var.prefix}-f5-bigip"
  }
}