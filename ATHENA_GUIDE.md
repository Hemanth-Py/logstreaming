# Athena Query & Optimization Guide

This guide provides the complete setup and best practices for querying CloudWatch logs stored in S3. 

---

## 🏗️ 1. Database Setup (DDL)

Run the following statement in the Athena console to create the main table. This uses **Partition Projection**, which eliminates the need for manual partition management.

### **The Table DDL**
```sql
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
PARTITIONED BY (year STRING, month STRING, day STRING, hour STRING)
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
```

### **The Flattened View**
CloudWatch logs are nested. Create this view to make them easy to query as a flat table.
```sql
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
```

---

## 🔍 2. Querying Capabilities

### **A. Basic Search (Latest Logs)**
Find the 50 most recent logs for a specific day.
```sql
SELECT * FROM cloudwatch_logs_flattened 
WHERE year = '2026' AND month = '02' AND day = '12'
ORDER BY event_time DESC 
LIMIT 50;
```

### **B. Filter by Lambda Function**
```sql
SELECT event_time, message 
FROM cloudwatch_logs_flattened 
WHERE logGroup = '/aws/lambda/logstreaming-demo_one-dev'
  AND year = '2026' AND month = '02'
ORDER BY event_time DESC;
```

### **C. Error Detection (Keyword Search)**
Find all logs containing the word "Error" or "Exception".
```sql
SELECT logGroup, event_time, message 
FROM cloudwatch_logs_flattened 
WHERE (message LIKE '%Error%' OR message LIKE '%Exception%')
  AND year = '2026'
LIMIT 100;
```

---

## 💡 3. Athena Best Practices

### **1. Always Use Partition Pruning**
*   **Best Practice:** Always include `year`, `month`, and `day` in your `WHERE` clause.
*   **Why:** This prevents Athena from scanning your entire S3 bucket, making queries **faster** and **cheaper** (you only pay for data scanned).

### **2. Limit Your Results**
*   **Best Practice:** Use `LIMIT 50` or `LIMIT 100` during development.
*   **Why:** Prevents the browser from hanging when displaying thousands of log lines.

### **3. Use the Flattened View**
*   **Best Practice:** Query `cloudwatch_logs_flattened` instead of the raw table.
*   **Why:** It handles the complex `UNNEST` logic for you, keeping your SQL clean.

### **4. Cost Monitoring**
*   **Insight:** Athena charges **$5.00 per TB** of data scanned. 
*   **Tip:** By using GZIP compression (configured in our Firehose) and Partition Projection, your scan volume is minimized to the extreme.

---

## 🛠️ Troubleshooting
*   **Empty Results?** Verify the S3 bucket name in the `LOCATION` and `template` properties matches your console.
*   **Missing Lambda?** Ensure the Lambda has been invoked at least once and wait 60 seconds for Firehose to flush the data to S3.
