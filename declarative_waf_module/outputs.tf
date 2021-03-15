output "waf_policy_ids" {
  value = [local.waf_policy_ids, local.suggestion_ids, merge(local.suggestions[0], local.suggestions[1])]
}