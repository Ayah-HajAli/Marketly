variable "project_name" {
  type = string
}

variable "github_owner" {
  type    = string
  default = "Ayah-HajAli"
}

variable "github_repo" {
  type    = string
  default = "Marketly"
}

variable "control_plane_instance_arn" {
  description = "ARN of the k3s control-plane instance, for scoping SSM send-command permission"
  type        = string
}

variable "ecr_repository_arns" {
  description = "List of ECR repo ARNs the CI role is allowed to push to"
  type        = list(string)
}