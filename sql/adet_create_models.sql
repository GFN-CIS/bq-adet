BEGIN
-- debug vars
    -- declare only_alert string;
    -- declare force bool;
    -- set force = TRUE;
    -- set only_alert = 'alert_name'; # if you want to create alert for single model only
    for models in (
        select FORMAT ("CREATE %t model `%t` %t", IF(force=TRUE," OR REPLACE ", " IF NOT EXISTS "), model_name, model_ddl) as q, model_name, alert_name
         from `${dataset}.adet_config` where if(alert_name is not null, only_alert=alert_name ,true)
         )
    DO
        BEGIN
            execute immediate models.q;
             call ${dataset}.adet_do_log ("INFO", models.alert_name, "model_train",
                TO_JSON_STRING( (select as struct models.model_name as model_name, models.q as query )));
        exception
             when error then
             call ${dataset}.adet_do_log ("ERROR",models.alert_name, "model_train",
                TO_JSON_STRING( (select as struct models.model_name as model_name, @@error.message as message, models.q as query )));
        END;
    end for;
END;