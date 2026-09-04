variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "control_plane_instance_id" {
  type = string
}

variable "worker_asg_name" {
  type = string
}

variable "target_port" {
  description = "Fixed NodePort that Traefik's Service will be pinned to on every k3s node"
  type        = number
  default     = 30080
}