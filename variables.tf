variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region to deploy resources in"
  default     = "us-central1"
}

variable "artifact_repo" {
  description = "Artifact Registry repository name where container images are pushed"
  type        = string
  default     = "sample-repo"   # change this to your preferred repo name
}

variable "image_tag" {
  description = "Image tag to deploy"
  type        = string
  default     = "v1"
}