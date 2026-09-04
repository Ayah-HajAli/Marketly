variable "project_name" {
  type = string
}

variable "repository_names" {
  description = "One ECR repo per service"
  type        = list(string)
  default     = ["auth-service", "catalog-service", "orders-service", "frontend"]
}