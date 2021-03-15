# This file automatically generates subnets and IPs based on the values provided to the module:

locals {
  # Get the VPC CIDR.
  cidr = var.cidr

  #    ***** MGMT *****
  #
  # Auto generate the public MGMT subnet from the CIDR.
  mgmt_cidrs = [cidrsubnet(local.cidr, 3, 0)]

  # After the subnets are created, we can get the mgmt subnet IDs
  mgmt_subnet_ids = aws_subnet.auto_public[0].id

  # Auto generate the mgmt IP (.4) using the mgmt subnet.
  mgmt_ips = {
    for each_cidr in local.mgmt_cidrs :
    each_cidr => [for i in range(1) :
      cidrhost(each_cidr, (i + 4))
    ]
  }

  #    ***** PRIVATE *****
  #
  # Auto generate the private subnet from the CIDR.
  priv_cidrs = [cidrsubnet(local.cidr, 3, 7)]

  # After the subnets are created, we can get the private subnet IDs
  priv_subnet_ids = aws_subnet.auto_private[0].id

  # Create a simple list of just the 'tmm' SELF IPs.  Need this list to loop through, in order to define self-ips.
  priv_ips = [
    for each_cidr in local.priv_cidrs : format("%s/%s", cidrhost(each_cidr, 4), element(split("/", each_cidr), 1))
  ]

  #    ***** PUBLIC *****
  #
  
  # Determine how many public 'tmm' subnets are required. For example, you might set the max_ip_count_per_subnet to 20, because that is
  # the maximum number of IPs an EC2 instance can support on a single interface.  Therefore if you need 25 public IPs, we would need two
  # public subnets, the first could accommodate 20 IPs and the second could accommodate the remaining 5 IPs.
  # '-1' subtracts one self-ip, for each interface, from the calculation.
  pub_cidr_qty = min((var.total_vs_ip_count / (var.max_ip_count_per_nic -1)), 20)

  # Auto generate a list containing the correct quantity of public 'tmm' subnets.   
  pub_cidrs = [
    for i in range(local.pub_cidr_qty) : cidrsubnet(local.cidr, 3, (i + 1))
  ]

  # Auto generate a list of all public ('mgmt' and 'tmm') subnets.
  all_pub_cidrs = [
    for i in range(local.pub_cidr_qty + 1) : cidrsubnet(local.cidr, 3, (i))
  ]

  # Auto generate the correct quantity of public 'tmm' IPs, using as many subnets as necessary. Creates a map of subnets, each containing a list of IPs.
  pub_ips = {
    for index, each_cidr in local.pub_cidrs :  
      each_cidr => [for i in range(1, (var.max_ip_count_per_nic + 1)) :
        cidrhost(each_cidr, i + 3) if ((index * var.max_ip_count_per_nic) + i) <= (var.total_vs_ip_count + length(local.pub_cidrs) )
      ]
  }

  # Create simple list of just the 'tmm' IPs.  Need this list to loop through, in order to attach EIPs to each of them.
  pub_ips_list = flatten([
    for each_subnet in local.pub_ips :
    each_subnet
  ])

  # Create a simple list of just the 'tmm' SELF IPs.  Need this list to loop through, in order to define self-ips.
  pub_self_ips_list = [
    for each_cidr in local.pub_cidrs : format("%s/%s", cidrhost(each_cidr, 4), element(split("/", each_cidr), 1))
  ]

  # Create a simple list of just the 'tmm' VS IPs
  pub_vs_ips_list = flatten([
    for index, each_cidr in local.pub_ips :
    [for each_ip in each_cidr :
      format("%s/%s", each_ip, element(split("/", index), 1)) if each_ip != cidrhost(index, 4)
    ]
  ])

  # Create a complex list of arrays containing VS IP, EIP and DNS name.
  pub_vs_eips_list = [
    for eip in aws_eip.f5-pub[*] : {
      private_ip = eip.private_ip
      public_ip  = eip.public_ip
      public_dns = eip.public_dns
    } if contains(local.pub_vs_ips_list, format("%s/%s", eip.private_ip, element(split("/", local.pub_cidrs[0]), 1)))
  ]  

  # After the subnets are created, we can get the public subnet IDs
  pub_subnet_ids = slice(aws_subnet.auto_public[*].id, 1, length(aws_subnet.auto_public))

  # # After the subnets are created (see aws_subnet resource blocks below), we can gather the subnet IDs
  pub_and_mgmt_subnet_ids = aws_subnet.auto_public[*].id
  
  # Take the app_list provided to the module by parent and append the module allocated Virtual Server IPs, along with the AWS region and the associated EIP, to the 
  # list for use in the AS3 template.
  app_list = [
    for index, each_app in var.app_list : concat(each_app, [local.pub_vs_eips_list[index].private_ip], [var.region], [local.pub_vs_eips_list[index].public_ip]  )
  ]
}

resource "aws_subnet" "auto_public" {
  count             = length(local.all_pub_cidrs)
  vpc_id            = var.vpc_id
  cidr_block        = local.all_pub_cidrs[count.index]
  availability_zone = var.az


  tags = {
    Name = "bigip_module_auto_pubic_${count.index}"
  }
}

resource "aws_subnet" "auto_private" {
  count             = length(local.priv_cidrs)
  vpc_id            = var.vpc_id
  cidr_block        = local.priv_cidrs[count.index]
  availability_zone = var.az

  tags = {
    Name = "bigip_module_auto_private_${count.index}"
  }
}

resource "aws_route_table" "auto_pub_bigip" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name = "auto_pub_bigip"
  }
}

resource "aws_route_table_association" "auto_pub_bigip" {
  count          = length(local.pub_and_mgmt_subnet_ids)
  subnet_id      = local.pub_and_mgmt_subnet_ids[count.index]
  route_table_id = aws_route_table.auto_pub_bigip.id
}