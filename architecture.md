# Components Used in This Project

## GCP Services

- **Artifact Registry**  
  - Stores Docker images (`gcr.io/<PROJECT_ID>/sample-app:v1`).  
  - Used as the image source for **Cloud Run**.  
  - Integrated with GitHub Actions for CI/CD.

- **Cloud Run**  
  - Runs the application container (`sample-app` from Dockerfile).  
  - Deployed using Terraform `google_cloud_run_service`.

- **Cloud SQL (PostgreSQL / MySQL)**  
  - Managed database for application data.  
  - Encrypted at rest with **KMS keys**.  
  - Automated backups enabled.

- **Secret Manager**  
  - Stores sensitive secrets (DB passwords, API keys).  
  - Access controlled via IAM roles.

- **IAM (Identity and Access Management)**  
  - Service accounts with **least privilege**.  
  - Role-based access for Terraform, GitHub Actions, Cloud Run, and DB.

- **KMS (Key Management Service)**  
  - Manages encryption keys for **Cloud SQL** and **Secret Manager**.

- **Cloud Storage (GCS)** *(optional)*  
  - Stores backups, artifacts, and logs if required.  
  - Encrypted using KMS.

- **Cloud Logging & Monitoring (Stackdriver)**  
  - Collects logs from Cloud Run, Cloud SQL, IAM.  
  - Alerts configured for suspicious activities or failures.

---

## Infrastructure as Code

- **Terraform**  
  - Manages all infrastructure (Cloud Run, SQL, IAM, KMS, Artifact Registry).  
  - State stored securely in a GCS bucket (if remote backend enabled).

- **Terraform Variables** (`variables.tf`)  
  - Used for project ID, regions, DB names, etc.

---

## Security & Compliance

- **IAM Roles & Policies** → Least privilege for all services.  
- **Audit Logging** → Monitoring IAM and DB activities.  
- **Encryption with KMS** → Secrets + database data encrypted at rest.  

---

## CI/CD

- **GitHub Actions Workflow (`.github/workflows/terraform.yml`)**  
  - Runs `terraform init/plan/apply`.  
  - Authenticates with GCP using service account key.  
  - Deploys Docker image → Artifact Registry → Cloud Run.  

- **Dockerfile**  
  - Packages app into a lightweight container (`python:3.10-slim`).  
  - Pushes to **Artifact Registry**.  

---

## Observability

- **Alerts & Monitoring Rules**  
  - Trigger alerts on:  
    - Cloud Run failures (5xx errors).  
    - Cloud SQL errors (connection/refused).  
    - IAM policy changes.  
  - Severity levels: Low / Medium / High.  

---

 **End-to-End Flow:**  
**Code (GitHub)** → **Build (Dockerfile)** → **Push (Artifact Registry)** → **Deploy (Terraform → Cloud Run)** → **Store (Cloud SQL, Secret Manager, GCS)** → **Monitor & Secure (Logging, Monitoring, IAM, KMS)**
