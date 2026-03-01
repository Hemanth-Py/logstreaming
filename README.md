# AWS Log Streaming & Analysis

A serverless data pipeline for streaming logs in real-time and performing SQL-based analysis.

### Architecture
* **Kinesis Data Firehose:** Buffers and delivers log data to S3.
* **Amazon S3:** Scalable storage for raw and partitioned log data.
* **Amazon Athena:** Executes SQL queries directly on S3 data for rapid analysis.

### Features
* Automated log partitioning for query optimization.
* Configurable buffering for cost/latency balance.
* Schema-on-read capability using AWS Glue Data Catalog.