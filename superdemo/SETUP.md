# Setup Guide

This guide outlines how to prepare your local workstation and GCP environment to deploy the Application Integration super-demo.

## Prerequisites

Ensure you have the following CLI utilities installed:
1. **Google Cloud SDK (`gcloud` CLI)**: [Install gcloud SDK](https://cloud.google.com/sdk/docs/install)
2. **Curl**: Usually pre-installed on MacOS and Linux.
3. **`integrationcli` (Google Cloud Application Integration Toolkit)**: [Install integrationcli](https://github.com/GoogleCloudPlatform/application-integration-management-toolkit).

## Step 1: Configure `env.sh`

1. Copy the environment variables template:
```bash
cd superdemo
cp env.example.sh env.sh
```
2. Open `env.sh` in your text editor and update the following properties:
   - `PROJECT_ID`: Set to your active GCP Project ID.
   - `REGION`: Set to your closest supported Application Integration region (e.g., `us-central1` or `europe-west1`).
3. Source your env file:
```bash
source env.sh
```

## Step 2: Initialize gcloud & Configure Credentials

Configure and authenticate your Google Cloud SDK environment by running the following commands:

1. **Initialize gcloud SDK** (if you have not done so or need to configure a new profile):
```bash
gcloud init
```

2. **Authenticate Application Default Credentials (ADC)**:
   The `integrationcli` tool uses Google's standard Application Default Credentials to securely authorize deployments:
```bash
gcloud auth application-default login
```
   This will open a browser window and request access to your GCP account.

3. **Set Quota Project for ADC**:
   Set your target project as the billing/quota project for ADC calls to ensure proper API permission evaluation:
```bash
gcloud auth application-default set-quota-project $PROJECT_ID
```

## Step 3: Run Automatic Project Setup

Execute the setup script from your terminal to enable the necessary Google Cloud Application Integration service APIs:

```bash
./setup.sh
```

## Step 4: Execute Deployment

Run the automated deployment script to deploy all 14 standard, connector-free integrations:

```bash
./deploy.sh
```
The script will verify your environment credentials, confirm `integrationcli` is available, and deploy each sample step-by-step.

Use [GUIDE.md](GUIDE.md) to learn how to run and test each integration