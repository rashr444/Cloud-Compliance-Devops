resource "google_logging_project_sink" "all_logs" {
  name        = "all-logs-sink"
  project     = var.project
  destination = "storage.googleapis.com/${google_storage_bucket.compliance_bucket.name}"
  filter      = ""
  unique_writer_identity = true
}
