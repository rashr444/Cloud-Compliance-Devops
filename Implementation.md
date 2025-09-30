# Implemenatation Of Services

This document provides a detailed breakdown of all services implemented in the Terraform-based GCP infrastructure project. It explains how each service is configured, dependencies between them, and the order of implementation. This ensures reproducibility, maintainability, and clarity for future updates.

## Infrastructure Foundation
## Google Cloud Project Setup with Terraform

A dedicated Google Cloud Project was provisioned, and IAM roles and bindings were applied via Terraform to ensure **least-privilege access**.

### Steps

1. **Enable Required APIs**
   - Activate all APIs needed for the project:
    - Compute Engine: compute.googleapis.com
    - Cloud SQL: sqladmin.googleapis.com
    - Cloud Run: run.googleapis.com
    - Secret Manager: secretmanager.googleapis.com
    - Key Management Service (KMS): cloudkms.googleapis.com
    - Cloud Logging: logging.googleapis.com

2. **Define IAM Roles and Bindings**
   - Apply least-privilege IAM roles :
    - roles/secretmanager.secretAccessor → Access secrets from Secret Manager.
    - roles/cloudsql.client → Connect and manage Cloud SQL instances.
    - roles/cloudkms.cryptoKeyDecrypter → Decrypt data using KMS crypto keys.
    - roles/logging.logWriter → Write logs to Cloud Logging for audit and monitoring.
    - roles/run.invoker → Allow invocation of Cloud Run services.
    - roles/viewer → Read-only access to view resources.
    - roles/editor → (If required elsewhere) General resource modification access.
    - roles/storage.admin → Manage Cloud Storage buckets and objects (if needed for backups or logs).
     
## Terraform Backend Setup

After configuring IAM and enabling required APIs, the next step is to set up **Terraform backend** for state management.

### Steps

1. **Create a Service Account**
   - Provision a dedicated service account with **necessary permissions**:
     - `roles/storage.admin` → To manage GCS buckets.
     - `roles/iam.serviceAccountUser` → To allow Terraform to impersonate the service account.
     - `roles/editor` → For resource creation during Terraform runs.
   - Download the service account key JSON for Terraform authentication.

2. **Create a GCS Bucket for Terraform State**
   - This bucket will store your Terraform state files securely.
   ```bash
   gsutil mb -l <REGION> gs://my-terraform-state-bucket

3. **Configure Terraform Backend in main.tf
   - which contains information of the structure

## Terraform Implementation Overview

This `main.tf` provisions a complete GCP environment with IAM, KMS, Secret Manager, Cloud SQL, Cloud Run, Storage, and monitoring.

---

### Configure Terraform Varaible 
- Set up the google provider with project, region, and service account authentication:
```hcl
provider "google" {
  project     = var.project
  region      = var.region
  credentials = file("<SERVICE_ACCOUNT_KEY>.json")
}
```

### Key Management Service (KMS)
- Enabled centralized encryption for sensitive data as per below format in main.tf:
  ```hcl {
  resource "google_kms_key_ring" "keyring" {
  name     = "demo-keyring"
  location = var.region
  project  = var.project
}
resource "google_kms_crypto_key" "crypto" {
  name     = "demo-key"
  key_ring = google_kms_key_ring.keyring.id
}
}```

## Infrastructure Components

### Networking (VPC & Firewall)
- **Custom VPC**: `devops-vpc` created.
- **Subnets**: Defined for controlled resource segmentation.
- **Firewall Rules**: Configured to allow only necessary traffic (e.g., SSH, HTTPS).

Provides **network isolation** and **security** for cloud resources.

### Cloud SQL (Managed Database)
- **PostgreSQL instance** provisioned with Terraform.
- **Automated backups** enabled for resilience.
- **Database credentials** stored securely in **Secret Manager**.

Ensures a **persistent, managed database** with secure credential handling.

### Secret Manager
- Stores:
  - Database password
  - API keys
  - Other sensitive configuration
- Managed with `google_secret_manager_secret` in Terraform.

Ensures **no secrets** are exposed in GitHub or Terraform code.

---

### Storage Bucket (GCS)
- Stores logs, backups, and compliance data with versioning.
```hcl
resource "google_storage_bucket" "compliance_bucket" {
  name          = "${var.project}-compliance-bucket"
  location      = var.region
  force_destroy = true

  versioning { enabled = true }
}
```

### Artifact Registry (Container Repository)
- **Private Docker registry** for application images.
- Docker authentication:
  ```bash
  gcloud auth configure-docker us-central1-docker.pkg.dev

Build & push application image:
```hcl
docker build -t us-central1-docker.pkg.dev/<PROJECT_ID>/sample-repo/sample-app:v1 .
docker push us-central1-docker.pkg.dev/<PROJECT_ID>/sample-repo/sample-app:v1
```

### Cloud Run & Docker Application
- Deploy containerized serverless application with auto-scaling.
```hcl{
resource "google_cloud_run_service" "sample" {
  name     = "sample-app"
  location = var.region
  project  = var.project

  template {
    spec {
      service_account_name = google_service_account.run_sa.email
      containers {
        image = "gcr.io/cloudrun/hello"
        env {
          name  = "DB_INSTANCE_CONNECTION_NAME"
          value = google_sql_database_instance.postgres.connection_name
        }
        env {
          name  = "DB_USER"
          value = google_sql_user.postgres_user.name
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  role     = "roles/run.invoker"
  member   = "allUsers"
  project  = google_cloud_run_service.sample.project
  location = google_cloud_run_service.sample.location
  service  = google_cloud_run_service.sample.name
}
```
## Monitoring & Alerts

### Cloud Monitoring & Logging
-Metrics and dashboards enabled.

### Alerting Policies
Alerts configured for:
 - Cloud Run CPU/Memory thresholds
 - DB connections and storage usage
 - Uptime checks for application endpoints
 - Notification channels: email and Slack.

## CI/CD Integration
### GitHub Actions + Terraform
- Workflow (terraform.yml) runs terraform init, plan, and apply.
- Uses service account credentials stored in GitHub Secrets.

### GitHub Actions + Docker Deployment
Workflow (deploy.yml) builds Docker image → pushes to Artifact Registry → deploys to Cloud Run.

Steps:
- Checkout source code.
- Build Docker image.
- Authenticate with GCP (gcloud auth activate-service-account).
- Push image to Artifact Registry.
- Run gcloud run deploy with new image.

# Implementation Order Summary
- IAM & Project Setup
- VPC & Networking
- Firewall Rules
- Artifact Registry
- Docker Build & Push
- Secret Manager
- Cloud SQL (DB Layer)
- Cloud Storage (Backups, State)
- Cloud Run (Application Layer)
- Monitoring & Alerts
- CI/CD Integration (Terraform + Docker Deployments)
- Security Hardening
