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
  project = google_cloud_run_service.sample.project
  location = google_cloud_run_service.sample.location
  service = google_cloud_run_service.sample.name

  role   = "roles/run.invoker"
  member = "allUsers"
}

output "cloud_run_url" {
  value       = google_cloud_run_service.sample.status[0].url
  description = "Public URL for the sample Cloud Run service"
}
