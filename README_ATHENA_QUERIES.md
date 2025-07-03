# Athena Query Guide for CloudWatch Logs

This guide shows how to query CloudWatch logs stored in S3 using Amazon Athena with the optimized table structure.

## 🏗️ **Architecture Overview**

```
CloudWatch Logs → Kinesis Firehose → S3 (partitioned) → Athena
```

- **No Lambda processing** - Direct storage of CloudWatch logs
- **Automatic partitioning** - By year/month/day/hour
- **GZIP compression** - Optimized storage and query performance
- **JSON native parsing** - Athena handles CloudWatch JSON structure

## 📊 **Table Structure**

### Main Table: `cloudwatch_logs`
```sql
-- Native CloudWatch logs structure
CREATE EXTERNAL TABLE cloudwatch_logs (
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
```

### Flattened View: `cloudwatch_logs_flattened`
```sql
-- Easier to query - flattens logEvents array
SELECT 
  logGroup,
  logStream,
  CAST(logEvents.timestamp AS TIMESTAMP) as event_time,
  logEvents.message,
  logEvents.id
FROM cloudwatch_logs_flattened
```

## 🔍 **Example Queries**

### 1. **Basic Log Search**
```sql
-- Find all logs from a specific function
SELECT 
  logGroup,
  logStream,
  event_time,
  message
FROM cloudwatch_logs_flattened
WHERE year='2024' AND month='01' AND day='15'
  AND logGroup = '/aws/lambda/my-function'
ORDER BY event_time DESC
LIMIT 100;
```

### 2. **Error Detection**
```sql
-- Find all error messages
SELECT 
  logGroup,
  event_time,
  message
FROM cloudwatch_logs_flattened
WHERE year='2024' AND month='01'
  AND (message LIKE '%ERROR%' OR message LIKE '%Exception%')
ORDER BY event_time DESC;
```

### 3. **Log Volume Analysis**
```sql
-- Count logs by function and hour
SELECT 
  logGroup,
  hour,
  COUNT(*) as log_count
FROM cloudwatch_logs_flattened
WHERE year='2024' AND month='01' AND day='15'
GROUP BY logGroup, hour
ORDER BY log_count DESC;
```

### 4. **Performance Monitoring**
```sql
-- Find slow Lambda executions
SELECT 
  logGroup,
  event_time,
  message
FROM cloudwatch_logs_flattened
WHERE year='2024' AND month='01'
  AND message LIKE '%Duration:%'
  AND CAST(REGEXP_EXTRACT(message, 'Duration: ([0-9.]+) ms', 1) AS DOUBLE) > 1000
ORDER BY event_time DESC;
```

### 5. **Cross-Function Analysis**
```sql
-- Compare error rates across functions
SELECT 
  logGroup,
  COUNT(*) as total_logs,
  SUM(CASE WHEN message LIKE '%ERROR%' THEN 1 ELSE 0 END) as error_count,
  ROUND(SUM(CASE WHEN message LIKE '%ERROR%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as error_rate
FROM cloudwatch_logs_flattened
WHERE year='2024' AND month='01'
GROUP BY logGroup
HAVING total_logs > 10
ORDER BY error_rate DESC;
```

### 6. **Time-based Analysis**
```sql
-- Log volume by hour of day
SELECT 
  EXTRACT(HOUR FROM event_time) as hour_of_day,
  COUNT(*) as log_count
FROM cloudwatch_logs_flattened
WHERE year='2024' AND month='01'
GROUP BY EXTRACT(HOUR FROM event_time)
ORDER BY hour_of_day;
```

## 🚀 **Performance Tips**

### 1. **Always Use Partition Pruning**
```sql
-- ✅ Good - Uses partitions
WHERE year='2024' AND month='01' AND day='15'

-- ❌ Bad - Scans all partitions
WHERE event_time > '2024-01-15'
```

### 2. **Use the Flattened View for Simple Queries**
```sql
-- ✅ Use flattened view for simple searches
FROM cloudwatch_logs_flattened

-- ❌ Don't manually unnest unless needed
FROM cloudwatch_logs CROSS JOIN UNNEST(logEvents)
```

### 3. **Limit Results for Interactive Queries**
```sql
-- Always add LIMIT for interactive queries
LIMIT 1000
```

### 4. **Use LIKE for Pattern Matching**
```sql
-- ✅ Good for text search
WHERE message LIKE '%ERROR%'

-- ❌ Avoid regex unless necessary
WHERE REGEXP_LIKE(message, 'ERROR')
```

## 📈 **Cost Optimization**

### 1. **Partition Projection**
The table uses partition projection to avoid MSCK REPAIR:
```sql
TBLPROPERTIES (
  'projection.enabled' = 'true',
  'projection.year.range' = '2020,2030'
)
```

### 2. **Compression**
- **GZIP compression** reduces storage costs
- **60-second buffering** optimizes file sizes

### 3. **Query Optimization**
- Use specific partitions
- Limit result sets
- Use flattened view for simple queries

## 🔧 **Maintenance**

### 1. **Add New Partitions (if needed)**
```sql
-- Usually not needed with partition projection
MSCK REPAIR TABLE cloudwatch_logs;
```

### 2. **Check Table Statistics**
```sql
-- Analyze table for better query planning
ANALYZE TABLE cloudwatch_logs COMPUTE STATISTICS;
```

### 3. **Monitor Query Performance**
- Use Athena query history
- Check data scanned vs. data returned
- Optimize slow queries

## 🎯 **Common Use Cases**

1. **Debugging**: Find specific error messages
2. **Monitoring**: Track log volumes and patterns
3. **Performance**: Identify slow operations
4. **Security**: Audit access patterns
5. **Compliance**: Generate log reports

## 📝 **Notes**

- **No Lambda required** - Simpler, more reliable
- **Native JSON support** - Athena handles CloudWatch format
- **Automatic partitioning** - Based on Firehose prefix
- **Cost-effective** - Only pay for queries, not processing 