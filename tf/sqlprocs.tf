module "template_files" {
  source               = "hashicorp/dir/template"
  template_file_suffix = ".sql"
  base_dir             = "${path.module}/../sql"
  template_vars        = {
    "dataset" = local.adet_dataset_id
    "project" = var.project_id
  }
}
resource "google_bigquery_routine" "adet_drop_old_models" {
  dataset_id      = local.adet_dataset_id
  definition_body = module.template_files.files.adet_drop_old_models.content
  language        = "SQL"
  project         = var.project_id
  routine_id      = "adet_drop_old_models"
  routine_type    = "PROCEDURE"
}
resource "google_bigquery_routine" "adet_create_models" {
  dataset_id      = local.adet_dataset_id
  language        = "SQL"
  project         = var.project_id
  routine_id      = "adet_create_models"
  routine_type    = "PROCEDURE"
  definition_body = module.template_files.files.adet_create_models.content
  arguments {
    data_type = jsonencode(
    {
      typeKind = "STRING"
    }
    )
    name      = "only_alert"
  }
  arguments {
    data_type = jsonencode(
    {
      typeKind = "BOOL"
    }
    )
    name      = "force"
  }
}
resource "google_bigquery_routine" "adet_retrain_models" {
  dataset_id      = local.adet_dataset_id
  definition_body = module.template_files.files.adet_retrain_models.content
  language        = "SQL"
  project         = var.project_id
  routine_id      = "adet_retrain_models"
  routine_type    = "PROCEDURE"
}
resource "google_bigquery_routine" "adet_stat_significance" {
  dataset_id      = local.adet_dataset_id
  definition_body = module.template_files.files.adet_stat_significance.content
  language        = "SQL"
  project         = var.project_id
  routine_id      = "adet_stat_significance"
  routine_type    = "PROCEDURE"
  arguments {
    data_type = jsonencode(
    {
      typeKind = "STRING"
    }
    )
    name      = "query"
  }
  arguments {
    data_type = jsonencode(
    {
      typeKind = "INT64"
    }
    )
    name      = "noise_floor"
  }
  arguments {
    data_type = jsonencode(
    {
      typeKind = "INT64"
    }
    )
    name      = "num_tests"
  }

}
resource "google_bigquery_routine" "adet_canonical_ddl" {
  dataset_id      = local.adet_dataset_id
  definition_body = module.template_files.files.adet_canonical_ddl.content
  project         = var.project_id
  routine_id      = "adet_canonical_ddl"
  language        = "JAVASCRIPT"
  return_type     = jsonencode(
  {
    typeKind = "STRING"
  }
  )

  routine_type = "SCALAR_FUNCTION"

  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "source_table"
  }
  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "date_col"
  }
  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "metric_col"
  }
  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "group_cols"
  }
  arguments {
    data_type = jsonencode({ typeKind = "INT64" })
    name      = "train_window_days"
  }
  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "population_col"
  }
  arguments {
    data_type = jsonencode({ typeKind = "INT64" })
    name      = "min_population"
  }
}
resource "google_bigquery_routine" "adet_update_anomalies" {
  depends_on      = [google_bigquery_routine.adet_canonical_ddl, google_bigquery_routine.adet_get_anomalies_ddl]
  dataset_id      = local.adet_dataset_id
  definition_body = module.template_files.files.adet_update_anomalies.content
  language        = "SQL"
  project         = var.project_id
  routine_id      = "adet_update_anomalies"
  routine_type    = "PROCEDURE"
}
//(canonical_ddl STRING, model STRING, error_clause STRING, anomaly_threshold FLOAT64) RETURNS STRING LANGUAGE js AS R"""
resource "google_bigquery_routine" "adet_get_anomalies_ddl" {
  dataset_id      = local.adet_dataset_id
  definition_body = module.template_files.files.adet_get_anomalies_ddl.content
  project         = var.project_id
  routine_id      = "adet_get_anomalies_ddl"
  language        = "JAVASCRIPT"
  return_type     = jsonencode(
  {
    typeKind = "STRING"
  }
  )

  routine_type = "SCALAR_FUNCTION"

  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "canonical_ddl"
  }

  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "model"
  }

  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "error_clause"
  }

  arguments {
    data_type = jsonencode({ typeKind = "FLOAT64" })
    name      = "anomaly_threshold"
  }
}

resource "google_bigquery_routine" "adet_no_gaps_view_ddl" {
  dataset_id      = local.adet_dataset_id
  definition_body = module.template_files.files.adet_no_gaps_view_ddl.content
  project         = var.project_id
  routine_id      = "adet_no_gaps_view_ddl"
  language        = "JAVASCRIPT"
  routine_type    = "SCALAR_FUNCTION"
  return_type     = jsonencode(
  {
    structType = {
      fields = [
        {
          name = "ddl"
          type = { typeKind = "STRING" }
        },
        {
          name = "description"
          type = { typeKind = "STRING" }
        },
      ]
    }
    typeKind   = "STRUCT"
  }
  )

  arguments {
    data_type = jsonencode( { typeKind = "STRING" } )
    name      = "grouping_columns"
  }
  arguments {
    data_type = jsonencode( { typeKind = "STRING" } )
    name      = "metric_column"
  }
  arguments {
    data_type = jsonencode( { typeKind = "STRING" } )
    name      = "date_column"
  }
  arguments {
    data_type = jsonencode( { typeKind = "FLOAT64" } )
    name      = "min_metric"
  }
  arguments {
    data_type = jsonencode( { typeKind = "STRING" } )
    name      = "source_table"
  }
}
resource "google_bigquery_routine" "adet_do_log" {
  dataset_id      = local.adet_dataset_id
  definition_body = module.template_files.files.adet_do_log.content
  language        = "SQL"
  project         = var.project_id
  routine_id      = "adet_do_log"
  routine_type    = "PROCEDURE"
  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "severity"
  }
  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "name"
  }
  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "operation"
  }
  arguments {
    data_type = jsonencode({ typeKind = "STRING" })
    name      = "op_data"
  }

}
