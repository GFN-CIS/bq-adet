# bq-adet Automatic Anomaly Detection

Habr post in Russian explaining the purpose of Adet for https://habr.com/ru/post/599645/
## Deployment

```
gcloud auth application-default login --scopes=https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/bigquery
``` 

Above might fail, so you can just use the

```
gcloud auth  login --update-adc --enable-gdrive-access  
```

```
gcloud config set project your_project
gcloud iam service-accounts create adet-deployment --description="adet-deployment" --display-name="adet-deployment"
```

Upload Demo Adet config.xls to the Google Drive and convert it to the Google Sheets format

Grant adet-deployment service account viewers access to the Google Sheets

copy tf/variables.tf.example to the variables.tf and write your infrastructure parameters

deploy the infrastructure

```
cd tf 
terraform init
terraform apply 
```

During the apply, some API might not be enabled yet : BigQuery DataTransfer Service. Just follow the links from
terraform error report and enable required APIs and re-run apply

## Gaps in data and High-Order data

Sometimes you have to analyze the high-order data (averages and other), which are relying on other data. In this case,
when data is absent for some date, Adet has nothing to analyze - the is no subject for analysis. For example, if there
are no sales of particular good for some day, but in present day there was a bunch of sales, Adet will not react on this
because there is no record in timeseries. To solve this problem, you need to fill such data with zeroes (e.g. fill the
gaps). The function `adet_no_gaps_view_ddl` is to help with this task.

The call example:

`select adet.adet_no_gaps_view_ddl("GroupingColumn1, GroupingColumn2", "metric_column", "date_column", min_metric,
'data_source').ddl`

Will return the DDL for the view where data are grouped by GroupingColumn1 and GroupingColumn2, with gaps in
metric_column, filled with zeros in each group. 

Lower-order metric in some groups might not be worthy to analyze. When for some good you run 1K sales/daily, 
and for others - 1-3 in week, it could be good choice to remove 
these low-sale groups from the analysis for the matter of saving money on ML charges and reduce type 1 errors amount.
But, when some outsider became high-seller, it should be analyzed. For such case, the `min_metric` argument is used. 
Specify the minimum metric to include in the analysis.
When metric in some group reaches the minimum threshold, all past metrics in timeline for this group will be included.


## Using as Terraform module

```
module "adet" {
  source     = "git::https://github.com/GFNRussia/bq-adet.git//tf"
  dataset_id = "adet"
  location = "EU" #or another location
  config_file_id        = "https://docs.google.com/spreadsheets/d/rest of the sheets url"
  project_id            = "google project id"
  region                = "europe-west1"
  service_account_email = "adet-deployment@YOURPROJECTID.iam.gserviceaccount.com"
}
```