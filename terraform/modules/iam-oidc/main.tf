data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

locals {
  # Only the main branch can assume either role — matches the README's
  # workflows: ECR push and terraform apply both only happen on merge
  # to main, never on PR builds from other branches.
  github_sub = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main"
}

# ── Role 1: used by ci.yml — narrowly scoped ────────────────────────
resource "aws_iam_role" "ci" {
  name = "${var.project_name}-github-ci-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = local.github_sub }
      }
    }]
  })
}

resource "aws_iam_role_policy" "ci" {
  name = "${var.project_name}-github-ci-policy"
  role = aws_iam_role.ci.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*" # this specific action has no resource-level permission support
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = var.ecr_repository_arns
      },
      {
        Sid      = "EC2Describe"
        Effect   = "Allow"
        Action   = "ec2:DescribeInstances"
        Resource = "*" # Describe* actions don't support resource-level restriction
      },
      {
        Sid      = "SSMSendCommand"
        Effect   = "Allow"
        Action   = ["ssm:SendCommand", "ssm:GetCommandInvocation"]
        Resource = [var.control_plane_instance_arn, "arn:aws:ssm:*:*:document/AWS-RunShellScript"]
      }
    ]
  })
}

# ── Role 2: used by terraform.yml — needs to manage the infra itself ─
resource "aws_iam_role" "terraform" {
  name = "${var.project_name}-github-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = local.github_sub }
      }
    }]
  })
}

# Broader by necessity — terraform apply manages every resource type
# across all 8 modules. Scoped to specific services rather than
# blanket AdministratorAccess.
resource "aws_iam_role_policy_attachment" "terraform_ec2" {
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_rds" {
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_elb" {
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_ecr" {
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_ssm" {
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_secrets" {
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "terraform_s3" {
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" # needed for the remote state bucket
}

resource "aws_iam_role_policy_attachment" "terraform_dynamodb" {
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" # needed for the lock table
}

# IAM management is the one genuinely dangerous permission Terraform
# needs (it creates roles for NAT/k3s/etc itself) — scoped narrowly
# to iam actions only, not full IAMFullAccess.
resource "aws_iam_role_policy" "terraform_iam_management" {
  name = "${var.project_name}-terraform-iam-management"
  role = aws_iam_role.terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
        "iam:PassRole", "iam:AttachRolePolicy", "iam:DetachRolePolicy",
        "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
        "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
        "iam:GetInstanceProfile", "iam:TagRole", "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies"
      ]
      Resource = "*"
    }]
  })
}