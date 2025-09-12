resource "google_service_account" "run_sa" {
  account_id   = "cloudrun-runner"
  display_name = "Cloud Run runtime service account"
  project      = var.project
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
