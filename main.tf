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

# --------------------
# Configuring alerts
# --------------------

resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
}

resource "google_monitoring_alert_policy" "cloudrun_latency" {
  display_name = "Cloud Run high latency (p95)"
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run p95 request latency"
    condition_threshold {
      # include resource.type for Cloud Run and optionally scope to a service/region
      filter = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_latencies\" AND resource.label.service_name = \"my-service\""

      # Align per series to a percentile (p95) over a 60s window, required for DELTA/distribution metrics
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_95"
        # no cross_series_reducer needed unless you want to combine across series
      }

      # compare the aligned value to threshold (units depend on the metric)
      comparison      = "COMPARISON_GT"
      threshold_value = 500    # example: 500 ms (adjust)
      duration        = "120s" # sustained for 2 minutes before alerting

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "DevOps Alerts Email"
  type         = "email"
  labels = {
    email_address = "your-email@example.com"
  }
}

resource "google_monitoring_alert_policy" "iam_role_change" {
  display_name = "Alert - IAM Role Change"
  combiner     = "OR"

  documentation {
    content   = "Alert when IAM role policies are changed (SetIamPolicy). Investigate the principal and change."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "IAM SetIamPolicy detected"
    condition_matched_log {
      filter = "protoPayload.methodName=\"SetIamPolicy\" AND resource.type=\"project\""
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s" # 5 minutes
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  enabled               = true
}

resource "google_monitoring_alert_policy" "auth_failures" {
  display_name = "Alert - Authentication Failures"
  combiner     = "OR"

  documentation {
    content   = "Alert on authentication failures recorded in audit logs (possible compromised credential attempts)."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "Failed auth events"
    condition_matched_log {
      filter = "protoPayload.status.code != 0 AND protoPayload.authenticationInfo.principalEmail:*"
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  enabled               = true
}

resource "google_monitoring_alert_policy" "cloudrun_5xx" {
  display_name = "Alert - Cloud Run 5xx Errors"
  combiner     = "OR"

  documentation {
    content   = "Alert when Cloud Run service returns many 5xx responses in a short period."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "Cloud Run 5xx errors detected"
    condition_matched_log {
      filter = "resource.type=\"cloud_run_revision\" AND jsonPayload.status>=500"
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  enabled               = true
}

resource "google_monitoring_alert_policy" "cloudsql_errors" {
  display_name = "Alert - Cloud SQL Errors"
  combiner     = "OR"

  documentation {
    content   = "Alert when Cloud SQL emits error logs or repeated connection failures."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "Cloud SQL Errors"
    condition_matched_log {
      filter = "resource.type=\"cloudsql_database\" AND severity=ERROR"
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  enabled               = true
}

resource "google_monitoring_alert_policy" "logging_sink_fail" {
  display_name = "Alert - Logging Sink Errors"
  combiner     = "OR"

  documentation {
    content   = "Alert when creating logging sinks or export operations fail."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "Logging sink error"
    condition_matched_log {
      filter = "resource.type=\"project\" AND protoPayload.methodName:(\"logging.sinks.create\" OR \"sinks.update\") AND protoPayload.status.code != 0"
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  enabled               = true
}
