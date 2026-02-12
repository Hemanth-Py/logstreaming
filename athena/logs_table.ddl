-- Optimized Athena table for CloudWatch logs
-- This table handles the native CloudWatch logs JSON structure
CREATE EXTERNAL TABLE IF NOT EXISTS cloudwatch_logs (
  messageType STRING,
  owner STRING,
  logGroup STRING,
  logStream STRING,
  subscriptionFilters ARRAY<STRING>,
  logEvents ARRAY<STRUCT<
    id: STRING,
    timestamp: BIGINT,
    message: STRING
  >>
)
PARTITIONED BY (
  year STRING,
  month STRING,
  day STRING,
  hour STRING
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'ignore.malformed.json' = 'true',
  'case.insensitive' = 'true'
)
LOCATION 's3://logstreaming-dev-logs/logs/'
TBLPROPERTIES (
  'projection.enabled' = 'true',
  'projection.year.type' = 'integer',
  'projection.year.range' = '2024,2030',
  'projection.month.type' = 'integer',
  'projection.month.range' = '1,12',
  'projection.month.digits' = '2',
  'projection.day.type' = 'integer',
  'projection.day.range' = '1,31',
  'projection.day.digits' = '2',
  'projection.hour.type' = 'integer',
  'projection.hour.range' = '0,23',
  'projection.hour.digits' = '2',
  'storage.location.template' = 's3://logstreaming-dev-logs/logs/year=${year}/month=${month}/day=${day}/hour=${hour}'
);

-- Flattened view for easier querying
CREATE OR REPLACE VIEW cloudwatch_logs_flattened AS
SELECT 
  logGroup,
  logStream,
  from_unixtime(logEvent.timestamp / 1000) as event_time,
  logEvent.message,
  logEvent.id,
  year,
  month,
  day,
  hour
FROM cloudwatch_logs
CROSS JOIN UNNEST(logEvents) AS t(logEvent);

-- Example search query:
-- SELECT * FROM cloudwatch_logs_flattened 
-- WHERE year = '2026' AND month = '02' AND day = '12'
-- ORDER BY event_time DESC LIMIT 50;
