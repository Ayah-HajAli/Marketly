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
output "db_address" {
  value = module.rds.db_address
}

output "db_secret_arn" {
  value = module.rds.secret_arn
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "github_ci_role_arn" {
  value = module.iam_oidc.ci_role_arn
}

output "github_terraform_role_arn" {
  value = module.iam_oidc.terraform_role_arn
}