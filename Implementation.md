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


2. **Configure Terraform Provider**
   - Set up the `google` provider with service account authentication:
     ```hcl
     provider "google" {
       project     = "<PROJECT_ID>"
       region      = "<REGION>"
       credentials = file("<SERVICE_ACCOUNT_KEY>.json")
     }
     ```

3. **Define IAM Roles and Bindings**
   - Apply least-privilege IAM roles in `iam.tf`:
     ```hcl
     resource "google_project_iam_member" "example" {
       project = "<PROJECT_ID>"
       role    = "roles/viewer"
       member  = "serviceAccount:<SERVICE_ACCOUNT_EMAIL>"
     }
     ```
   - *(Add additional IAM bindings as per your project requirements)*

### Notes

- **Dependencies**: These steps must be completed **first**, as all other services depend on IAM configurations and enabled APIs.
- Ensures a secure foundation for provisioning other GCP resources.

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
  



