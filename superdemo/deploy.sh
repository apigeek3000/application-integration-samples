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

# Deployment result tracking
SUCCEEDED=()
FAILED=()
SKIPPED=()

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
    SKIPPED+=("$sample")
    continue
  fi
  
  # 1. Setup isolated staging folder
  rm -rf "$STAGING_DIR"
  mkdir -p "$STAGING_DIR/src"
  
  # 2. Copy all JSON definitions
  cp "$SAMPLE_SRC_DIR"/*.json "$STAGING_DIR/src/"
  
  # 3. Perform placeholder substitutions and metadata patching
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

      # Patch databasePersistencePolicy, cloudLoggingSeverity, and empty EmailTask To-recipients to prevent API validation errors
      if command -v jq &> /dev/null; then
        jq '
          (.taskConfigs[]? | select(.task == "EmailTask") | .parameters.To.value.stringArray) |= (
            if .stringValues == null or .stringValues == [] then
              .stringValues = ["noreply@example.com"]
            else
              .
            end
          ) |
          . + {
            "databasePersistencePolicy": "DATABASE_PERSISTENCE_POLICY_UNSPECIFIED",
            "cloudLoggingDetails": {
              "cloudLoggingSeverity": "CLOUD_LOGGING_SEVERITY_UNSPECIFIED"
            }
          }
        ' "$json_file" > "$json_file.tmp" && mv "$json_file.tmp" "$json_file"
      elif command -v node &> /dev/null; then
        node -e '
          const fs = require("fs");
          const file = process.argv[1];
          const data = JSON.parse(fs.readFileSync(file, "utf8"));
          
          if (data.taskConfigs) {
            data.taskConfigs.forEach(t => {
              if (t.task === "EmailTask" && t.parameters && t.parameters.To && t.parameters.To.value && t.parameters.To.value.stringArray) {
                const sa = t.parameters.To.value.stringArray;
                if (!sa.stringValues || sa.stringValues.length === 0) {
                  sa.stringValues = ["noreply@example.com"];
                }
              }
            });
          }
          
          data.databasePersistencePolicy = "DATABASE_PERSISTENCE_POLICY_UNSPECIFIED";
          data.cloudLoggingDetails = {
            cloudLoggingSeverity: "CLOUD_LOGGING_SEVERITY_UNSPECIFIED"
          };
          
          fs.writeFileSync(file, JSON.stringify(data, null, 2), "utf8");
        ' "$json_file"
      else
        # Fallback sed patch replacing the final closing brace of the JSON object
        if [ "$IS_DARWIN" = true ]; then
          sed -i '' -e '$s/}/, "databasePersistencePolicy": "DATABASE_PERSISTENCE_POLICY_UNSPECIFIED", "cloudLoggingDetails": { "cloudLoggingSeverity": "CLOUD_LOGGING_SEVERITY_UNSPECIFIED" } }/' "$json_file"
        else
          sed -i -e '$s/}/, "databasePersistencePolicy": "DATABASE_PERSISTENCE_POLICY_UNSPECIFIED", "cloudLoggingDetails": { "cloudLoggingSeverity": "CLOUD_LOGGING_SEVERITY_UNSPECIFIED" } }/' "$json_file"
        fi
      fi
    fi
  done
  
  # 4. Deploy using integrationcli and ADC (--default-token)
  echo "🚀 Applying integration artifacts..."
  if integrationcli integrations apply -f "$STAGING_DIR" -p "$PROJECT_ID" -r "$REGION" --default-token --wait; then
    echo "✅ Successfully deployed $sample!"
    SUCCEEDED+=("$sample")
  else
    echo "❌ Failed to deploy $sample."
    FAILED+=("$sample")
  fi
  
  # 5. Cleanup staging
  rm -rf "$STAGING_DIR"
done

echo ""
echo "=========================================================="
echo "✨ All selected super-demo samples processed!"
echo "=========================================================="
echo ""
echo "=========================================================="
echo "📊 Deployment Summary"
echo "=========================================================="
echo "Total samples:  ${#SAMPLES[@]}"
echo "✅ Succeeded:   ${#SUCCEEDED[@]}"
echo "❌ Failed:      ${#FAILED[@]}"
echo "⚠️  Skipped:    ${#SKIPPED[@]}"
echo "----------------------------------------------------------"

if [ ${#SUCCEEDED[@]} -gt 0 ]; then
  echo ""
  echo "✅ Successful deployments:"
  for sample in "${SUCCEEDED[@]}"; do
    echo "   - $sample"
  done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
  echo ""
  echo "❌ Failed deployments:"
  for sample in "${FAILED[@]}"; do
    echo "   - $sample"
  done
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo ""
  echo "⚠️  Skipped samples (source directory missing):"
  for sample in "${SKIPPED[@]}"; do
    echo "   - $sample"
  done
fi

echo ""
echo "=========================================================="

# Exit non-zero if any deployment failed
if [ ${#FAILED[@]} -gt 0 ]; then
  exit 1
fi
