#!/bin/bash
# Copyright 2026 Google LLC
# Licensed under the Apache License, Version 2.0

# ==============================================================================
# Google Cloud Configuration
# ==============================================================================

# Target GCP Project ID where Application Integration is enabled
export PROJECT_ID="your-gcp-project-id"

# Target GCP Region for Application Integration (e.g., us-central1)
export REGION="us-central1"

# Auto-resolve PROJECT_NUMBER if authenticated and gcloud is installed
if [ "$PROJECT_ID" != "your-gcp-project-id" ] && command -v gcloud &> /dev/null; then
  export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)" 2>/dev/null)
  export PROJECT_NUMBER
fi
