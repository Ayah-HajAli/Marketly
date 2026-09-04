variable "project_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "k3s_sg_id" {
  type = string
}

variable "control_plane_instance_type" {
  type    = string
  default = "t3.small"
}

variable "worker_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "worker_min_size" {
  type    = number
  default = 1
}

variable "worker_max_size" {
  type    = number
  default = 3
}

variable "worker_desired_capacity" {
  type    = number
  default = 1
}