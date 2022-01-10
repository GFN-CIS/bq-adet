if (error_clause === null)
{
  error_clause='FALSE';
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
                            else SAFE_DIVIDE(metric, ABS(((upper_bound + lower_bound)) / 2)) end as divergence, if($${error_clause}, TRUE, FALSE) as is_error
from ( select combined.is_anomaly, lower_bound, upper_bound, anomaly_probability, canonical.*,
           case true when canonical.metric > upper_bound
                                       then "Higher"
                                   when canonical.metric < lower_bound
                                       then "Lower"
                                   else "Middle" end as direction
       from combined
                left join canonical using (date_col, group_cols) ) where date_col is not NULL and group_cols is not NULL`;