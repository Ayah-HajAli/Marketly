#!/usr/bin/env bash
set -euo pipefail


PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AWS_REGION="eu-north-1"

echo "=== Step 1: Terraform apply ==="
cd "$PROJECT_ROOT/terraform"
terraform init -input=false
terraform apply -auto-approve

CONTROL_PLANE_ID=$(terraform output -raw control_plane_instance_id)
echo "Control-plane instance: $CONTROL_PLANE_ID"

echo ""
echo "=== Step 2: Deploy to Kubernetes via SSM ==="

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$CONTROL_PLANE_ID" \
  --document-name "AWS-RunShellScript" \
  --region "$AWS_REGION" \
  --parameters 'commands=[
    "cd /tmp/Marketly || git clone https://github.com/Ayah-HajAli/Marketly.git /tmp/Marketly",
    "cd /tmp/Marketly && git pull origin main",
    "kubectl apply -f k8s/namespace.yaml",
    "kubectl apply -f k8s/traefik-nodeport.yaml",
    "kubectl apply -f k8s/auth-service/ -f k8s/catalog-service/ -f k8s/orders-service/ -f k8s/frontend/",
    "kubectl apply -f k8s/ingress.yaml",
    "kubectl rollout restart deployment/auth-service deployment/catalog-service deployment/orders-service deployment/frontend -n capstone",
    "kubectl rollout status deployment/auth-service -n capstone --timeout=120s",
    "kubectl rollout status deployment/catalog-service -n capstone --timeout=120s",
    "kubectl rollout status deployment/orders-service -n capstone --timeout=120s",
    "kubectl rollout status deployment/frontend -n capstone --timeout=120s"
  ]' \
  --query "Command.CommandId" \
  --output text)

echo "SSM command sent (ID: $COMMAND_ID). Waiting for it to finish..."

aws ssm wait command-executed \
  --command-id "$COMMAND_ID" \
  --instance-id "$CONTROL_PLANE_ID" \
  --region "$AWS_REGION" || true

STATUS=$(aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$CONTROL_PLANE_ID" \
  --region "$AWS_REGION" \
  --query "Status" \
  --output text)

echo ""
echo "=== Deployment output ==="
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$CONTROL_PLANE_ID" \
  --region "$AWS_REGION" \
  --query "StandardOutputContent" \
  --output text

if [ "$STATUS" != "Success" ]; then
  echo ""
  echo "Deployment FAILED (status: $STATUS). Error output:"
  aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$CONTROL_PLANE_ID" \
    --region "$AWS_REGION" \
    --query "StandardErrorContent" \
    --output text
  exit 1
fi

echo ""
echo "Deployment complete."