resource "google_kms_key_ring" "keyring" {
  name     = "demo-keyring"
  location = var.region
  project  = var.project
}

resource "google_kms_crypto_key" "crypto" {
  name     = "demo-key"
  key_ring = google_kms_key_ring.keyring.id
  project  = var.project
}