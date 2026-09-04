#!/bin/bash
set -euo pipefail

REGION="${region}"
PARAM_PREFIX="${param_prefix}"

# Wait until the control-plane has published its join info
until aws ssm get-parameter --region "$REGION" --name "$PARAM_PREFIX/server-url" >/dev/null 2>&1; do
  echo "Waiting for control-plane to publish join info..."
  sleep 10
done

SERVER_URL=$(aws ssm get-parameter --region "$REGION" --name "$PARAM_PREFIX/server-url" --query "Parameter.Value" --output text)
NODE_TOKEN=$(aws ssm get-parameter --region "$REGION" --name "$PARAM_PREFIX/node-token" --with-decryption --query "Parameter.Value" --output text)

curl -sfL https://get.k3s.io | K3S_URL="$SERVER_URL" K3S_TOKEN="$NODE_TOKEN" sh -