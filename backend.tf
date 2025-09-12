terraform {
  backend "gcs" {
    bucket = "tf-state-cloud-compliance-demo-471907-1757663605"
    prefix = "cloud-compliance-project/terraform.tfstate"
  }
}