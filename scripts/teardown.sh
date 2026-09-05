#!/usr/bin/env bash
set -euo pipefail



PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT/terraform"

echo "This will DESTROY all AWS infrastructure for this project:"
echo "  - VPC, subnets, NAT instance"
echo "  - k3s control-plane + worker Auto Scaling Group"
echo "  - RDS Postgres instance (and its data)"
echo "  - Application Load Balancer"
echo "  - ECR repositories (and any images in them)"
echo "  - IAM roles and OIDC provider"
echo ""
read -r -p "Type 'destroy' to confirm: " CONFIRMATION

if [ "$CONFIRMATION" != "destroy" ]; then
  echo "Confirmation did not match. Aborting — nothing was destroyed."
  exit 1
fi

echo ""
echo "Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "Teardown complete. Remember: the S3 state bucket and DynamoDB lock"
echo "table from the initial bootstrap step are NOT managed by Terraform"
echo "and will still exist — delete them manually from the AWS console"
echo "if you're fully done with this project."