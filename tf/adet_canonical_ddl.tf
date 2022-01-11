resource "google_bigquery_routine" "adet_canonical_ddl" {
  dataset_id      = local.adet_dataset_id
  definition_body = <<-EOT
population_clause = ' TRUE ';
if (population_col !== null & min_population !== null) { population_clause = `population>=$${min_population}`;
}
return `
WITH
  s AS (
  SELECT
    SAFE_CAST($${date_col} AS timestamp) AS date_col,
    SAFE_CAST($${metric_col} AS FLOAT64) AS metric,
    ARRAY_TO_STRING([$${group_cols}], '.') AS group_cols,
    SAFE_CAST($${population_col} as FLOAT64) as population,
    *
  FROM
    $${source_table} )
SELECT
  *
FROM
  s
WHERE
  date_col > IFNULL((
    SELECT
      TIMESTAMP_SUB(MAX(date_col), INTERVAL $${train_window_days} day) AS timestamp
    FROM
      s ),
    TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $${train_window_days} day))
  AND $${population_clause}` ;

  EOT
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