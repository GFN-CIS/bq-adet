resource "google_bigquery_table" "adet_config" {
  depends_on          = [
    google_bigquery_table.int_adet_config, google_bigquery_routine.adet_canonical_ddl,
    google_bigquery_routine.adet_get_anomalies_ddl
  ]
  dataset_id          = local.adet_dataset_id
  project             = var.project_id
  table_id            = "adet_config"
  deletion_protection = false
  view {
    query          = module.template_files.files.adet_config.content
    use_legacy_sql = false
  }
}
resource "google_bigquery_table" "adet_anomalies" {
  depends_on          = [google_bigquery_table.adet_cached_alerts]
  dataset_id          = local.adet_dataset_id
  project             = var.project_id
  table_id            = "adet_anomalies"
  deletion_protection = false
  view {
    query          = "select * from ${local.adet_dataset_id}.adet_cached_anomalies where is_anomaly = TRUE and is_filtered=FALSE"
    use_legacy_sql = false
  }
}
resource "google_bigquery_table" "adet_log" {
  dataset_id          = local.adet_dataset_id
  deletion_protection = false
  project             = var.project_id
  table_id            = "adet_log"
  lifecycle {
    prevent_destroy = false
  }
  schema              = jsonencode(
  [
    { name = "name", type = "STRING" },
    { name = "operation_time", type = "TIMESTAMP" },
    { name = "severity", type = "STRING" },
    { name = "operation", type = "STRING" },
    { name = "op_data", type = "STRING" }
  ]
  )

}
resource "google_bigquery_table" "int_adet_config" {
  dataset_id          = local.adet_dataset_id
  deletion_protection = false
  project             = var.project_id
  table_id            = "int_adet_config"
  lifecycle {
    prevent_destroy = false
  }
  external_data_configuration {
    autodetect    = true
    source_format = "GOOGLE_SHEETS"

    google_sheets_options {
      skip_leading_rows = 1
    }

    source_uris = [var.config_file_id]

  }
}
resource "google_bigquery_table" "adet_cached_alerts" {
  dataset_id          = local.adet_dataset_id
  deletion_protection = false
  table_id            = "adet_cached_anomalies"
  schema              = jsonencode(
  [
    { name = "alert_name", type = "STRING" },
    { name = "alert", type = "STRING" },
    { name = "explanation", type = "STRING" },
    { name = "entity", type = "STRING" },
    { name = "date_col", type = "TIMESTAMP" },
    { name = "group_cols", type = "STRING" },
    { name = "metric", type = "FLOAT" },
    { name = "is_anomaly", type = "BOOLEAN" },
    { name = "is_error", type = "BOOLEAN" },
    { name = "direction", type = "STRING" },
    { name = "divergence", type = "FLOAT" },
    { name = "population", type = "FLOAT" },
    { name = "lower_bound", type = "FLOAT" },
    { name = "upper_bound", type = "FLOAT" },
    { name = "anomaly_probability", type = "FLOAT" },
    { name = "is_filtered", type = "BOOLEAN" }
  ])

}
