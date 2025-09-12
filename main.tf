provider "google" {
  project = var.project
  region  = var.region
}

# --------------------
# Enable required APIs
# --------------------
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com"
  ])
  service = each.key
  project = var.project
}

# --------------------
# KMS: key ring + crypto key
# Note: do NOT set "project" inside google_kms_crypto_key (provider-level project is used)
# --------------------
resource "google_kms_key_ring" "keyring" {
  name     = "demo-keyring"
  location = var.region
  project  = var.project
}

resource "google_kms_crypto_key" "crypto" {
  name     = "demo-key"
  key_ring = google_kms_key_ring.keyring.id

  # optional rotation
  # rotation_period = "2592000s"
}

# --------------------
# Secret: generated DB password stored in Secret Manager
# Use `auto = true` in replication (automatic is deprecated)
# --------------------
resource "random_password" "db_password" {
  length  = 20
  special = true
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "demo-db-password"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}


# --------------------
# Cloud SQL Postgres + user + DB
# --------------------
resource "google_sql_database_instance" "postgres" {
  name             = "demo-postgres"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier              = "db-f1-micro"
    activation_policy = "ALWAYS"

    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    ip_configuration {
      ipv4_enabled = true
    }
  }
}

resource "google_sql_database" "app_db" {
  name     = "appdb"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "postgres_user" {
  name     = "dbuser"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}

# --------------------
# Storage bucket (encrypted with KMS) for logs/backups
# --------------------
resource "google_storage_bucket" "compliance_bucket" {
  name          = "${var.project}-compliance-bucket"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

}

# --------------------
# Service account for Cloud Run + IAM bindings
# --------------------
resource "google_service_account" "run_sa" {
  account_id   = "cloudrun-runner"
  display_name = "Cloud Run runtime service account"
}

resource "google_project_iam_member" "run_secret_access" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "run_cloudsql_client" {
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "run_kms_crypto_decrypter" {
  project = var.project
  role    = "roles/cloudkms.cryptoKeyDecrypter"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "run_logging_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

# --------------------
# Cloud Run service (sample public image)
# --------------------
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
  project  = google_cloud_run_service.sample.project
  location = google_cloud_run_service.sample.location
  service  = google_cloud_run_service.sample.name

  role   = "roles/run.invoker"
  member = "allUsers"
}

# --------------------
# Logging sink sending to the storage bucket
# --------------------
resource "google_logging_project_sink" "all_logs" {
  name                   = "all-logs-sink"
  project                = var.project
  destination            = "storage.googleapis.com/${google_storage_bucket.compliance_bucket.name}"
  filter                 = ""
  unique_writer_identity = true
}

