output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "alb_sg_id" {
  value = module.security_groups.alb_sg_id
}

output "k3s_sg_id" {
  value = module.security_groups.k3s_sg_id
}

output "rds_sg_id" {
  value = module.security_groups.rds_sg_id
}

output "nat_sg_id" {
  value = module.security_groups.nat_sg_id
}

output "nat_instance_id" {
  value = module.nat_instance.nat_instance_id
}

output "nat_public_ip" {
  value = module.nat_instance.nat_public_ip
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "control_plane_instance_id" {
  value = module.ec2_cluster.control_plane_instance_id
}

output "worker_asg_name" {
  value = module.ec2_cluster.worker_asg_name
}