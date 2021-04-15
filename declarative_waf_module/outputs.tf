output "waf_policy_ids" {
  value = [merge(local.suggestions[0], local.suggestions[1])]
}