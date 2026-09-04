data "aws_caller_identity" "current" {}
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
module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id
}

module "alb" {
  source = "./modules/alb"

  project_name              = var.project_name
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  alb_sg_id                 = module.security_groups.alb_sg_id
  control_plane_instance_id = module.ec2_cluster.control_plane_instance_id
  worker_asg_name           = module.ec2_cluster.worker_asg_name
}

module "iam_oidc" {
  source = "./modules/iam-oidc"

  project_name               = var.project_name
  github_owner               = "Ayah-HajAli"
  github_repo                = "Marketly"
  control_plane_instance_arn = "arn:aws:ec2:eu-north-1:${data.aws_caller_identity.current.account_id}:instance/${module.ec2_cluster.control_plane_instance_id}"
  ecr_repository_arns        = values(module.ecr.repository_arns)
}


