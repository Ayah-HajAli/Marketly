#!/bin/bash
set -euo pipefail

REGION="${region}"
PARAM_PREFIX="${param_prefix}"

# Install k3s server (control-plane also runs workloads by default, unlike kubeadm)
curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644

# Wait for the node token to exist before reading it
until [ -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

NODE_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Publish join info so workers can find and authenticate to this control-plane
aws ssm put-parameter --region "$REGION" --name "$PARAM_PREFIX/node-token" --type SecureString --value "$NODE_TOKEN" --overwrite
aws ssm put-parameter --region "$REGION" --name "$PARAM_PREFIX/server-url" --type String --value "https://$PRIVATE_IP:6443" --overwrite