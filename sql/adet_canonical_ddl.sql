population_clause = ' TRUE ';
if (population_col !== null & min_population !== null) { population_clause = `$${population}>=$${min_population}`;
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
