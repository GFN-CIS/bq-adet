provider "google" {
  project = var.project_id
  region  = "europe-west3"
  zone    = "EU"
  scopes  = [
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/bigquery",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}
