variable "project_name" {
  type = string
}

variable "public_subnet_id" {
  description = "Public subnet the NAT instance lives in"
  type        = string
}

variable "nat_sg_id" {
  type = string
}

variable "private_route_table_id" {
  description = "Private route table to add the 0.0.0.0/0 -> NAT route to"
  type        = string
}