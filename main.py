import google.auth
import gspread

schema_cols = ['type', 'alert', 'table', 'ml_columns', 'grouping_columns', 'entity_column', 'date_column',
               'population_col',
               'min_population', 'train_window_days', 'retrain_interval_days', 'anomaly_threshold', 'backfill_days',
               'error_check', 'region', 'granularity', 'explanation_format', 'comment']


def sync_schema_to_gsheets(sheets_url):
    cr, project = google.auth.default(["https://www.googleapis.com/auth/drive"])
    gc = gspread.Client(cr)

    sht2 = gc.open_by_url(
        sheets_url)
    ws = sht2.worksheet('sources')
    target_cols = ws.row_values(1)

    new_cols = [x for x in schema_cols if x not in target_cols]
    before_cols = ws.col_count
    ws.insert_cols([[x] for x in new_cols], col=before_cols)


sync_schema_to_gsheets(
    'https://docs.google.com/spreadsheets/d/1WUA7-SppOi07_F07d7dNvmuVo3cMqjkAYtFu8rjka0w/edit#gid=885329775')
