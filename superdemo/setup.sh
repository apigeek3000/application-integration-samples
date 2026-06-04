#!/bin/bash
# Copyright 2026 Google LLC
# Licensed under the Apache License, Version 2.0

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate and source env.sh
ENV_FILE="$SCRIPT_DIR/env.sh"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Error: env.sh not found inside $SCRIPT_DIR."
  echo "👉 Please copy env.example.sh to env.sh and configure your PROJECT_ID and REGION."
  exit 1
fi

source "$ENV_FILE"

# Validate environment variables
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "your-gcp-project-id" ]; then
  echo "❌ Error: PROJECT_ID is not configured in env.sh"
  exit 1
fi

echo "=========================================================="
echo "🛠️  Application Integration - Setup Utility"
echo "=========================================================="
echo "GCP Project: $PROJECT_ID"
echo "=========================================================="

# Verify gcloud is installed
if ! command -v gcloud &> /dev/null; then
  echo "❌ Error: Google Cloud SDK (gcloud) is not installed."
  exit 1
fi

# Ensure user is authenticated
echo "🔒 Verifying Google Cloud active account..."
ACTIVE_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
if [ -z "$ACTIVE_ACCOUNT" ]; then
  echo "❌ Error: No active gcloud account set."
  echo "👉 Please run: gcloud auth login"
  exit 1
fi
echo "✅ Active account: $ACTIVE_ACCOUNT"

# Set active project context
gcloud config set project "$PROJECT_ID" --quiet

# Enable Google Application Integration API
echo "🔌 Enabling Application Integration Service (integrations.googleapis.com)..."
if gcloud services enable integrations.googleapis.com --project="$PROJECT_ID"; then
  echo "✅ Application Integration API enabled successfully!"
else
  echo "❌ Failed to enable integrations.googleapis.com API."
  exit 1
fi

echo "=========================================================="
echo "✨ Setup complete! Proceed to run ./deploy.sh to deploy."
echo "=========================================================="
