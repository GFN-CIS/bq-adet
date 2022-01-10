begin
    for alert in (select alert_name, model_name from ${dataset}.adet_config m
         left join (select JSON_VALUE(op_data,"$.model_name") as model_name, max(operation_time) as last_trained from
                    ${dataset}.adet_log  where operation='model_train'  and severity!='ERROR' group by 1 ) t using (model_name)
                    where DATETIME_ADD(t.last_trained, interval retrain_interval_days day) < CURRENT_TIMESTAMP()  or t.last_trained  is NULL
                    )
    do
    call ${dataset}.adet_create_models(alert.alert_name, TRUE);

end for;

end;