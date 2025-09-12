resource "google_storage_bucket" "compliance_bucket" {
  name          = "${var.project}-compliance-bucket"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.crypto.id
  }
}