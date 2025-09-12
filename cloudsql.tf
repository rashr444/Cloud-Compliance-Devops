resource "google_sql_database_instance" "postgres" {
  name             = "demo-postgres"
  database_version = "POSTGRES_15"
  project          = var.project
  region           = var.region

  settings {
    tier               = "db-f1-micro"
    activation_policy  = "ALWAYS"

    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    ip_configuration {
      ipv4_enabled = false
    }
  }
}

resource "google_sql_database" "app_db" {
  name     = "appdb"
  instance = google_sql_database_instance.postgres.name
  project  = var.project
}

resource "google_sql_user" "postgres_user" {
  name     = "dbuser"
  instance = google_sql_database_instance.postgres.name
  project  = var.project
  password = random_password.db_password.result
}

output "db_instance_connection_name" {
  value       = google_sql_database_instance.postgres.connection_name
  description = "Use in Cloud Run or Cloud SQL connector"
}