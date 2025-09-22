# Cloud Compliance DevOps Project


This project demonstrates how to build a secure, compliant, and automated cloud infrastructure using:

    Terraform (Infrastructure as Code)
    GitHub Actions (CI/CD)
    Docker + Cloud Run (App Deployment)
    GCP Services (SQL, IAM, KMS, Secret Manager, Logging & Monitoring)
    Compliance Mapping (ISO 27001, GDPR, COBIT, DORA)

It’s designed as a portfolio-ready project that shows both DevOps skills and GRC (Governance, Risk, and Compliance) knowledge.


# Features

    Infrastructure as Code with Terraform
    CI/CD pipeline via GitHub Actions (Terraform runs automatically on push)
    Containerized Application deployed to Cloud Run
    Secrets Management with Google Secret Manager
    Encryption with Google KMS
    Automated Backups for Cloud SQL
    Logging & Monitoring for auditability
    Alerts for IAM changes, DB errors, login failures
    Compliance Mapping to major frameworks (ISO 27001, GDPR, COBIT, DORA)

# Compliance Mapping

See COMPLIANCE.md for details on how this project maps to:

    ISO 27001 (Access control, audit logging, encryption)
    GDPR (Data minimization, breach alerts, right to erasure)
    COBIT (Risk management, security services)
    DORA (Backups, incident classification, resilience testing)

# Monitoring & Alerts

Cloud Logging: All app + infra logs collected
Monitoring: Dashboards for system health
Alerts Configured for:
    IAM role changes
    Failed login attempts
    Database errors
    High latency
