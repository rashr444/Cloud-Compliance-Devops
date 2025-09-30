#Implemenatation Of Services

This document provides a detailed breakdown of all services implemented in the Terraform-based GCP infrastructure project. It explains how each service is configured, dependencies between them, and the order of implementation. This ensures reproducibility, maintainability, and clarity for future updates.

### 1.1. Infrastructure Foundation
## Google Cloud Project Setup with Terraform

A dedicated Google Cloud Project was provisioned, and IAM roles and bindings were applied via Terraform to ensure **least-privilege access**.

### Steps

1. **Enable Required APIs**
   - Activate all APIs needed for the project:
     - `compute.googleapis.com` (Compute Engine)
     - `sqladmin.googleapis.com` (Cloud SQL)
     - `run.googleapis.com` (Cloud Run)
     - *(Add any additional APIs your project requires)*

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


