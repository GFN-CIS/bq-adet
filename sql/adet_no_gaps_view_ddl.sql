this.ddl= `
 with data           as ( select array_to_string([$${grouping_columns}], '.') as data_grouping, $${metric_column} as metric,
                             $${date_column} as date_column, *
                         except
                         (
                         $${date_column}
                         ,
                         $${metric_column}
                         )
                         from $${source_table} )
   , data_above_min as ( select * from data where cast (metric as FLOAT64) > $${min_metric} )
   , starts         as ( select distinct first_value(date_column)
                                                     over (partition by data_grouping order by date_column) as first_date,
                             data_grouping
                         from data_above_min )
   , with_gaps      as ( select data.*, starts.first_date
                         from data
                                  left join starts
                         on data.data_grouping = starts.data_grouping and data.date_column >= starts.first_date
                         where starts.first_date is not null )
   , timelines      as ( select distinct data_grouping, metric_date, $${grouping_columns}
                         from with_gaps
                                  cross join unnest(generate_date_array(first_date, current_date())) as metric_date )
   , ready_data     as ( select metric_date, ifnull(metric, 0) as metric, b.*
                         except
                         (
                         metric
                         ,
                         data_grouping
                         ,
                         date_column
                         ),
                         $${grouping_columns}
                         from timelines a
                                  left join (select * except ($${grouping_columns}) from with_gaps) b
                         on a.metric_date = b.date_column and a.data_grouping = b.data_grouping )
select *
except
(
metric
,
metric_date,
first_date
)
,
metric as $${metric_column}
,
metric_date as $${date_column}
from ready_data
 `;
 this.description = `no_gaps_view_ddl($${grouping_columns}, $${metric_column}, $${date_column}, $${min_metric}, $${source_table})`;
 return this;

