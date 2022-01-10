 insert into ${dataset}.adet_log(severity, name, operation_time, operation, op_data) values (UPPER(severity), name,CURRENT_TIMESTAMP(), operation,
               op_data);