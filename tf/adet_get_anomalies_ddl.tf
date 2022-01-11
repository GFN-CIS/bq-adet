resource "google_bigquery_routine" "adet_get_anomalies_ddl" {
  dataset_id      = local.adet_dataset_id
  definition_body = <<-EOT
if (error_clause === null)
{
  error_clause='FALSE';
}
if (minimal_divergence === null)
{
  minimal_div_clause = 'FALSE';
}
else {
  minimal_div_clause = ` divergence < $${minimal_divergence} `;
}
return `
WITH canonical as ($${canonical_ddl} )
   , trained   AS ( select *
                    from ( SELECT *
                           FROM ML.DETECT_ANOMALIES(
                                   MODEL \`$${model}\`,
                                   STRUCT ($${anomaly_threshold} AS anomaly_prob_threshold)) )
                    where is_anomaly is not NULL )
   , newdata   AS ( select *
                    from ( SELECT *
                           FROM ML.DETECT_ANOMALIES(
                                   MODEL \`$${model}\`,
                                   STRUCT ($${anomaly_threshold} AS anomaly_prob_threshold),
                                   ( select date_col, metric, group_cols from canonical )) ) )
   , combined  as ( select date_col, metric, group_cols, is_anomaly, lower_bound, upper_bound, anomaly_probability
                    from trained
                    where is_anomaly is not NULL
                    union all
                    select date_col, metric, group_cols, is_anomaly, lower_bound, upper_bound, anomaly_probability
                    from newdata
                    where is_anomaly is not NULL )
select *,
    case true when direction = "Higher"
                                then SAFE_DIVIDE(metric, ABS(upper_bound)) - 1
                            when direction = "Lower"
                                then 1 - SAFE_DIVIDE(metric, ABS(lower_bound))
                            when metric = lower_bound and metric = upper_bound
                                then 0
                            else SAFE_DIVIDE(metric, ABS(((upper_bound + lower_bound)) / 2)) end as divergence, if($${error_clause}, TRUE, FALSE) as is_error, $${minimal_div_clause} as is_filtered
from ( select combined.is_anomaly, lower_bound, upper_bound, anomaly_probability, canonical.*,
           case true when canonical.metric > upper_bound
                                       then "Higher"
                                   when canonical.metric < lower_bound
                                       then "Lower"
                                   else "Middle" end as direction
       from combined
                left join canonical using (date_col, group_cols) ) where date_col is not NULL and group_cols is not NULL`;

          EOT
  #  module.template_files.files.adet_get_anomalies_ddl.content
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
  arguments {
    data_type = jsonencode({ typeKind = "FLOAT64" })
    name      = "minimal_divergence"
  }
}