output "repository_urls" {
  description = "Map of service name -> full ECR repository URL, e.g. for docker push"
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "repository_arns" {
  value = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}