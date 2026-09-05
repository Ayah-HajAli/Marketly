#!/usr/bin/env bash
set -euo pipefail



REQUIRED_TOOLS=(aws kubectl terraform docker git)
MISSING=()

echo "Checking required tools..."

for tool in "${REQUIRED_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    version_line=$("$tool" --version 2>&1 | head -n 1)
    echo "  ✓ $tool found ($version_line)"
  else
    echo "  ✗ $tool NOT FOUND"
    MISSING+=("$tool")
  fi
done

if [ ${#MISSING[@]} -ne 0 ]; then
  echo ""
  echo "Missing required tools: ${MISSING[*]}"
  echo "Install these before continuing. On macOS, most are available via Homebrew:"
  echo "  brew install awscli kubernetes-cli terraform docker git"
  exit 1
fi

echo ""
echo "Checking AWS credentials are active..."
if aws sts get-caller-identity >/dev/null 2>&1; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  echo "  ✓ AWS credentials valid (account: $ACCOUNT)"
else
  echo "  ✗ AWS credentials not configured or expired. Run 'aws configure' first."
  exit 1
fi

echo ""
echo "All required tools are installed and AWS credentials are valid. You're ready to go."