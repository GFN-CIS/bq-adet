BEGIN
    declare q string;
    declare upsert_fields string;
    declare insert_fields string;
    FOR cfg IN (
  SELECT
    *
  FROM
    ${dataset}.adet_config
    WHERE
    type='arima') DO
    set upsert_fields = (select string_agg(FORMAT("trg.%t=src.%t", column_name, column_name), ',')
                         from adet.INFORMATION_SCHEMA.COLUMNS
                         where table_name = 'adet_cached_anomalies'
                           and table_schema = '${dataset}'
                           and table_catalog = '${project}'
                           and column_name not in ('alert_name', 'date_col', 'group_cols'));
     set insert_fields = (select string_agg(FORMAT("%t",  column_name), ',')
                             from adet.INFORMATION_SCHEMA.COLUMNS
                             where table_name = 'adet_cached_anomalies'
                               and table_schema = '${dataset}'
                               and table_catalog = '${project}'
                              );
    set q =
            FORMAT("""
      MERGE INTO ${dataset}.adet_cached_anomalies trg USING (
          SELECT distinct %T as alert_name, %T as alert,FORMAT (%t) as explanation, %t as entity, date_col, group_cols,
          metric, is_anomaly, is_error, direction, divergence, lower_bound, upper_bound, anomaly_probability,population from (%t)
        ) src
        on src.alert_name=trg.alert_name and src.date_col=trg.date_col and src.group_cols=trg.group_cols
        WHEN MATCHED THEN
          UPDATE SET %t
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (%t) values(%t)
        """,
                   cfg.alert_name, cfg.alert, cfg.explanation_format, cfg.entity_column,
                   `${project}.${dataset}.adet_get_anomalies_ddl`(
                           `${project}.${dataset}.adet_canonical_ddl`(
                                   cfg.TABLE, cfg.date_column, cfg.ml_columns[OFFSET(0)],
                                   array_to_string(cfg.grouping_columns, ', '), cfg.train_window_days,
                                   cfg.population_col, cfg.min_population),
                           cfg.model_name, cfg.error_check, cfg.anomaly_threshold, cfg.minimal_divergence
                       ), upsert_fields, insert_fields, insert_fields
                );
    call ${dataset}.adet_do_log("INFO", cfg.alert_name, "anomaly_update",
                                TO_JSON_STRING((select as struct q as query)));
    BEGIN
        EXECUTE IMMEDIATE q;
    EXCEPTION
        when error then
        call ${dataset}.adet_do_log("ERROR", cfg.alert_name, "anomaly_update",
                                    TO_JSON_STRING((select as struct @@error.message as message, q as query)));

    END;
END
FOR;
END;