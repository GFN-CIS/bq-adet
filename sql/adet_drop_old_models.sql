begin
for model_name in (
SELECT
  DISTINCT name
FROM
  `${dataset}.adet_train_log`
LEFT JOIN
  `${dataset}.alerting.adet_models_ddl`
ON
  name=model_name
WHERE
  model_name IS NULL)
  do
  execute immediate FORMAT("drop model if exists `%t`", model_name.name);
  end for;
end;