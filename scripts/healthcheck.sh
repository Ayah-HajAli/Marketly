#!/usr/bin/env bash
set -euo pipefail


BASE_URL="${1:-http://localhost}"
AWS_REGION="eu-north-1"

declare -A SERVICES=(
  [auth-service]="5101/health"
  [catalog-service]="5102/health"
  [orders-service]="5103/health"
)

FAILED=0

echo "=== Checking service health at $BASE_URL ==="
for name in "${!SERVICES[@]}"; do
  path="${SERVICES[$name]}"
  url="$BASE_URL:$path"

  if [ "$BASE_URL" != "http://localhost" ]; then
    # Behind an ingress/ALB, there's one shared host, no per-service port.
    url="$BASE_URL/health"
  fi

  if response=$(curl -sf --max-time 5 "$url" 2>/dev/null); then
    echo "  ✓ $name healthy: $response"
  else
    echo "  ✗ $name UNREACHABLE at $url"
    FAILED=1
  fi
done

echo ""
echo "=== Checking Kubernetes pod status (if kubectl is configured for this cluster) ==="
if command -v kubectl >/dev/null 2>&1 && kubectl get ns capstone >/dev/null 2>&1; then
  kubectl get pods -n capstone
  NOT_READY=$(kubectl get pods -n capstone --no-headers | awk '$2 != "1/1"' | wc -l | tr -d ' ')
  if [ "$NOT_READY" -gt 0 ]; then
    echo "  ✗ $NOT_READY pod(s) not in a Ready state"
    FAILED=1
  else
    echo "  ✓ all pods Ready"
  fi
else
  echo "  (kubectl not configured for this cluster from here — skipping pod check.
   Run this script from inside an SSM session on the control-plane to include it.)"
fi

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "All checks passed."
  exit 0
else
  echo "One or more checks failed. See above for details."
  exit 1
fi