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
LOCATION 's3://logstreaming-logs/logs/'
TBLPROPERTIES (
  'projection.enabled' = 'true',
  'projection.year.type' = 'integer',
  'projection.year.range' = '2020,2030',
  'projection.month.type' = 'integer',
  'projection.month.range' = '1,12',
  'projection.day.type' = 'integer',
  'projection.day.range' = '1,31',
  'projection.hour.type' = 'integer',
  'projection.hour.range' = '0,23'
);

-- Alternative flattened table for easier querying (optional)
-- This creates a view that flattens the logEvents array
CREATE OR REPLACE VIEW cloudwatch_logs_flattened AS
SELECT 
  logGroup,
  logStream,
  CAST(logEvents.timestamp AS TIMESTAMP) as event_time,
  logEvents.message,
  logEvents.id,
  year,
  month,
  day,
  hour
FROM cloudwatch_logs
CROSS JOIN UNNEST(logEvents) AS t(logEvents);

-- Example queries for the optimized table:

-- 1. Query logs from a specific log group
-- SELECT 
--   logGroup,
--   logStream,
--   CAST(logEvents.timestamp AS TIMESTAMP) as event_time,
--   logEvents.message
-- FROM cloudwatch_logs
-- CROSS JOIN UNNEST(logEvents) AS t(logEvents)
-- WHERE year='2024' AND month='01' AND day='15'
--   AND logGroup = '/aws/lambda/my-function';

-- 2. Find error messages
-- SELECT 
--   logGroup,
--   logEvents.message
-- FROM cloudwatch_logs
-- CROSS JOIN UNNEST(logEvents) AS t(logEvents)
-- WHERE year='2024' AND month='01'
--   AND logEvents.message LIKE '%ERROR%';

-- 3. Count logs by log group
-- SELECT 
--   logGroup,
--   COUNT(*) as log_count
-- FROM cloudwatch_logs
-- CROSS JOIN UNNEST(logEvents) AS t(logEvents)
-- WHERE year='2024' AND month='01'
-- GROUP BY logGroup
-- ORDER BY log_count DESC;
