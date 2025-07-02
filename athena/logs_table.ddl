CREATE EXTERNAL TABLE IF NOT EXISTS logstreaming_logs (
  message string,
  timestamp string,
  logStream string,
  logGroup string
)
PARTITIONED BY (
  year string,
  month string,
  day string,
  hour string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://your-bucket-name/logs/'
;
