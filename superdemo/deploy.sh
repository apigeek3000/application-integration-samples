#!/bin/bash
# Copyright 2026 Google LLC
# Licensed under the Apache License, Version 2.0

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

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

if [ -z "$REGION" ]; then
  echo "❌ Error: REGION is not configured in env.sh"
  exit 1
fi

echo "=========================================================="
echo "🚀 Application Integration - Super-Demo Deployment Utility"
echo "=========================================================="
echo "GCP Project: $PROJECT_ID"
echo "Region:      $REGION"
echo "=========================================================="

# Verify gcloud is installed
if ! command -v gcloud &> /dev/null; then
  echo "❌ Error: Google Cloud SDK (gcloud) is not installed."
  exit 1
fi

# Verify Application Default Credentials (ADC)
echo "🔒 Validating Application Default Credentials (ADC)..."
if ! gcloud auth application-default print-access-token &>/dev/null; then
  echo "❌ Error: Application Default Credentials (ADC) are not authenticated."
  echo "👉 Please run: gcloud auth application-default login"
  exit 1
fi
echo "✅ ADC validated successfully!"

# Set active project context
gcloud config set project "$PROJECT_ID" --quiet

# Ensure integrationcli is available
export PATH="$PATH:$HOME/.integrationcli/bin"

if ! command -v integrationcli &> /dev/null; then
  echo "❌ Error: integrationcli is not installed or not in PATH."
  echo "👉 Please refer to SETUP.md to install integrationcli before running this script."
  exit 1
fi
echo "✅ integrationcli is ready!"

# Define standard samples to deploy
SAMPLES=(
  "call-rest-api"
  "case-conversion"
  "catch-task-error"
  "concat-string-array"
  "ecom-order-processing"
  "ecom-order-processing-using-data-transformer"
  "filter-json-array"
  "foreach-loop-send-email"
  "merge-json-arrays"
  "remove-json-property"
  "resolve-json"
  "status-based-retry"
  "string-to-uppercase"
  "update-json-array"
)

# Staging directory for deployments
STAGING_DIR="$SCRIPT_DIR/tmp_deploy"

# Determine OS for sed differences
IS_DARWIN=false
if [[ "$(uname)" == "Darwin" ]]; then
  IS_DARWIN=true
fi

# Iterate and deploy each sample
for sample in "${SAMPLES[@]}"; do
  echo ""
  echo "----------------------------------------------------------"
  echo "📦 Deploying Sample: $sample"
  echo "----------------------------------------------------------"
  
  SAMPLE_SRC_DIR="$REPO_DIR/src/$sample"
  if [ ! -d "$SAMPLE_SRC_DIR" ]; then
    echo "⚠️  Warning: Directory $SAMPLE_SRC_DIR does not exist. Skipping."
    continue
  fi
  
  # 1. Setup isolated staging folder
  rm -rf "$STAGING_DIR"
  mkdir -p "$STAGING_DIR/src"
  
  # 2. Copy all JSON definitions
  cp "$SAMPLE_SRC_DIR"/*.json "$STAGING_DIR/src/"
  
  # 3. Perform placeholder substitutions
  echo "🔧 Replacing PROJECT_ID and REGION placeholders..."
  for json_file in "$STAGING_DIR/src"/*.json; do
    if [ -f "$json_file" ]; then
      if [ "$IS_DARWIN" = true ]; then
        sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" "$json_file"
        sed -i '' "s/REGION/$REGION/g" "$json_file"
      else
        sed -i "s/PROJECT_ID/$PROJECT_ID/g" "$json_file"
        sed -i "s/REGION/$REGION/g" "$json_file"
      fi
    fi
  done
  
  # 4. Deploy using integrationcli and ADC (--default-token)
  echo "🚀 Applying integration artifacts..."
  if integrationcli integrations apply -f "$STAGING_DIR" -p "$PROJECT_ID" -r "$REGION" --default-token --wait; then
    echo "✅ Successfully deployed $sample!"
  else
    echo "❌ Failed to deploy $sample."
  fi
  
  # 5. Cleanup staging
  rm -rf "$STAGING_DIR"
done

echo ""
echo "=========================================================="
echo "✨ All selected super-demo samples processed!"
echo "=========================================================="
