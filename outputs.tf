# --------------------
# Outputs
# --------------------
output "cloud_run_url" {
  value       = google_cloud_run_service.sample.status[0].url
  description = "Public URL for the sample Cloud Run service"
}

output "db_instance_connection_name" {
  value       = google_sql_database_instance.postgres.connection_name
  description = "Use in Cloud Run or Cloud SQL connector"
}

output "db_password_length" {
  value       = length(random_password.db_password.result)
  description = "Length of the generated DB password"
  sensitive   = true
}