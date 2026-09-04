output "db_address" {
  value = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = var.db_name
}

output "db_username" {
  value = var.db_username
}

output "secret_arn" {
  description = "AWS Secrets Manager ARN holding the real password — fetch it via `aws secretsmanager get-secret-value`, never print it in terraform output"
  value       = aws_secretsmanager_secret.db_credentials.arn
}