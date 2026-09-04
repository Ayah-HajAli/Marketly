output "ci_role_arn" {
  description = "Put this in GitHub repo secrets as AWS_CI_ROLE_ARN, referenced in ci.yml"
  value       = aws_iam_role.ci.arn
}

output "terraform_role_arn" {
  description = "Put this in GitHub repo secrets as AWS_TERRAFORM_ROLE_ARN, referenced in terraform.yml"
  value       = aws_iam_role.terraform.arn
}