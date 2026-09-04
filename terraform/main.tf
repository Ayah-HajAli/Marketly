module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
}

module "nat_instance" {
  source = "./modules/nat-instance"

  project_name           = var.project_name
  public_subnet_id       = module.vpc.public_subnet_ids[0]
  nat_sg_id              = module.security_groups.nat_sg_id
  private_route_table_id = module.vpc.private_route_table_id
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

module "ec2_cluster" {
  source = "./modules/ec2-cluster"

  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  k3s_sg_id          = module.security_groups.k3s_sg_id
}

# rds, alb, iam-oidc
# modules get added here one at a time, in that order, as we build each one
# ec2-cluster, rds, alb, iam-oidc
# modules get added here one at a time, in that order, as we build each one

# ecr, ec2-cluster, rds, alb, iam-oidc
# modules get added here one at a time, in that order, as we build each one
# modules get added here one at a time, in that order, as we build each one