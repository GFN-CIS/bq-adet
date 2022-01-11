(with data as (select *
               except
               (
               ml_columns
               ,
               grouping_columns
               ,
               minimal_divergence
               )
               ,
               REGEXP_EXTRACT_ALL(ml_columns, '\\w+') as ml_columns
               ,
               REGEXP_EXTRACT_ALL(grouping_columns, '\\w+') as grouping_columns
               ,
               to_hex(sha1(alert)) as alert_name
               ,
               safe_cast(minimal_divergence as float64) as minimal_divergence
               from `${dataset}.int_adet_config`
--                             left join `${dataset}.int_alerting_fields` using (table)
               where type is not null)
    , data2 as (select *
                except
                (
                explanation_format
                )
                ,
                ifnull(explanation_format,
                       FORMAT(
                               "\"%t for %%t on %%t is %%t, range %%.2f-%%.2f\", group_cols, date_col, metric, lower_bound, upper_bound",
                               ARRAY_TO_STRING(ml_columns, '-'))) as explanation_format
                ,
                concat('adet_sys_', REGEXP_EXTRACT(alert_name, '[[:alpha:]]'),
                       ARRAY_TO_STRING(REGEXP_EXTRACT_ALL(alert_name, '_([[:alpha:]])'), ''),
                       '_') as alert_prefix
                ,
                '${project}' as project_name
                ,
                '${dataset}' as dataset_name
                from data)
    , canonical
        as (select *
                 , ${dataset}.adet_canonical_ddl(data2.table
                , data2.date_column
                , data2.ml_columns[offset(0)]
                , array_to_string(data2.grouping_columns
                                                     , ', ')
                , data2.train_window_days
                , data2.population_col
                , data2.min_population) as canonical_ddl
            from data2)
    , models as (select *,
                        format("""
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
                      TIME_SERIES_TIMESTAMP_COL= "date_col",
                      TIME_SERIES_DATA_COL = "metric",
                      TIME_SERIES_ID_COL = "group_cols",
                      AUTO_ARIMA=TRUE,
                      HOLIDAY_REGION = %T,
                      DATA_FREQUENCY = %T
              ) AS
             SELECT date_col, metric, group_cols from ( %t
        ) where date_col<timestamp_sub(CURRENT_TIMESTAMP(), interval cast (%d as int64) day) """,
                               IFNULL(region, 'RU'), IFNULL(granularity, 'DAILY'), canonical.canonical_ddl,
                               ifnull(safe_cast(backfill_days as int64), 0)) as model_ddl
                 from canonical)
 select *,
        TO_HEX(sha1(model_ddl))                                                                 as model_ddl_hash,
        format("%t.%t.%t%t", project_name, dataset_name, alert_prefix, TO_HEX(sha1(model_ddl))) as model_name
 from models)