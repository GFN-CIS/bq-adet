resource "google_bigquery_dataset" "adet_dataset" {

  dataset_id = var.dataset_id
  delete_contents_on_destroy = true
  location = var.location
  project = var.project_id
}
locals {
  adet_dataset_id = google_bigquery_dataset.adet_dataset.dataset_id
}
resource "google_project_iam_member" "sa_roles" {
  for_each = toset(["roles/bigquery.jobUser", "roles/bigquery.dataViewer"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${var.service_account_email}"
}

resource "google_bigquery_dataset_access" "adet_sa_access" {
  dataset_id    = google_bigquery_dataset.adet_dataset.dataset_id
  role          = "OWNER"
  user_by_email = var.service_account_email
}

resource "google_bigquery_data_transfer_config" "retrain_job" {
  display_name   = "adet-retrain-${local.adet_dataset_id}"
  location       = var.location
  data_source_id = "scheduled_query"
  schedule       = "every day 00:00"
  params         = {
    query = "call ${local.adet_dataset_id}.adet_retrain_models(); call ${local.adet_dataset_id}.adet_update_anomalies();  "
  }
  service_account_name = var.service_account_email
}

resource "google_bigquery_data_transfer_config" "update_job" {
  display_name   = "adet-update-${local.adet_dataset_id}"
  location       = var.location
  data_source_id = "scheduled_query"
  schedule       = "every 6 hours"
  params         = {
    query = "call ${local.adet_dataset_id}.adet_update_anomalies();  "
  }
  service_account_name = var.service_account_email

}


