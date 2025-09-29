### Compliance Mapping for Cloud-Compliance-DevOps

This document explains how the infrastructure and DevOps setup in this project maps to key security & compliance frameworks.
It helps demonstrate that the system is designed with best practices, governance, risk management, and compliance (GRC) in mind.

# Framework Mapping

This document maps our Terraform-based GCP infrastructure setup to compliance frameworks (ISO 27001, GDPR, COBIT, DORA).

---

## ISO 27001

| Control | Description | Implementation in this project |
|---------|-------------|--------------------------------|
| **A.9 Access Control** | Ensure users only have the permissions they need (least privilege). | IAM roles are created in Terraform with least privilege (service accounts + restricted roles). |
| **A.12 Operations Security** | Enable monitoring and logging for systems. | Cloud Logging + Monitoring enabled in Terraform (logs stored, alerts configured). |
| **A.18 Compliance** | Ensure sensitive data is encrypted and compliant with regulations. | KMS encryption is applied to Cloud SQL + Secret Manager secrets. |

---

## GDPR

| Principle | Description | Implementation in this project |
|-----------|-------------|--------------------------------|
| **Data Minimization** | Only collect/store necessary data. | Database schemas only include essential fields (design decision). |
| **Right to Erasure** | Users can request deletion of their data. | Provide SQL script / API endpoint to delete user records from Cloud SQL. |
| **Data Breach Notification** | Must notify in case of a breach. | Alerts are configured for failed logins, IAM changes, DB errors → triggers incident response plan. |

---

## COBIT

| Control | Description | Implementation in this project |
|---------|-------------|--------------------------------|
| **APO13 Risk Management** | Identify and manage IT risks. | Risks documented (IAM misconfig, SQL exposure). Controls implemented with IAM + private networking. |
| **DSS05 Security Services** | Protect systems with security services. | IAM enforcement, Secret Manager for credentials, Cloud Logging for audit trails. |

---

## DORA (Digital Operational Resilience Act)

| Control | Description | Implementation in this project |
|---------|-------------|--------------------------------|
| **ICT Risk Management** | Backup and protect systems against failure. | Cloud SQL automated backups + storage snapshot policies. |
| **Incident Classification** | Label and respond to incidents. | Alerts configured in Monitoring with severity levels (low/medium/high). |
| **Resilience Testing** | Test recovery from failures. | Recovery simulation: intentionally fail Cloud SQL → restore from backup snapshot. |

---

This mapping shows how security, compliance, and resilience controls are enforced through **Terraform + GCP services**.
