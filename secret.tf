resource "random_password" "db_password" {
  length  = 20
  special = true
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "demo-db-password"
  replication {
    automatic = true
  }
  project = var.project
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
  project = var.project
}

output "db_password_length" {
  value       = length(random_password.db_password.result)
  description = "Length of the generated DB password"
}
