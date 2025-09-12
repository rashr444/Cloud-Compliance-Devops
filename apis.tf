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