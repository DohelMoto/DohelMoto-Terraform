output "external_secrets_irsa_role_arn" {
  description = "ARN of the IAM role for External Secrets Operator"
  value       = module.external_secrets_irsa.iam_role_arn
}
