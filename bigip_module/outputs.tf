output "mgmt_cidrs" {
  value = local.mgmt_cidrs
}

output "pub_cidrs" {
  value = local.pub_cidrs
}

output "priv_cidrs" {
  value = local.priv_cidrs
}

output "all_pub_cidrs" {
  value = local.all_pub_cidrs
}

output "mgmt_ips" {
  value = local.mgmt_ips
}

output "mgmt_pub_ips" {
  value = aws_eip.f5-mgmt
}

output "pub_ips" {
  value = local.pub_ips
}

output "priv_ips" {
  value = local.priv_ips
}

output "pub_ips_list" {
  value = local.pub_ips_list
}

output "pub_self_ips_list" {
  value = local.pub_self_ips_list
}

output "pub_vs_ips_list" {
  value = local.pub_vs_ips_list
}

output "pub_vs_eips_list" {
  value = local.pub_vs_eips_list
}

output "mgmt_subnet_ids" {
  value = local.mgmt_subnet_ids
}

output "pub_subnet_ids" {
  value = local.pub_subnet_ids
}

output "priv_subnet_ids" {
  value = local.priv_subnet_ids
}

output "pub_and_mgmt_subnet_ids" {
  value = local.pub_and_mgmt_subnet_ids
}

output "f5_password" {
  value = random_string.password.result
}

output "f5_username" {
  value = var.f5_user
}

output "app_list_eip" {
  value = local.app_list
}







