# Production Ready system

## Improvements

- Redshift:
    - Use redshift spectrum to maintain two clusters, one for high load analysis scripts, andother for fast and short analysis scriptgs
    - In case of failure of one of the cluster, move query from unheathy to the healthy cluster
- ingestion_lambda function:
    - Use fanout to download large amount of files by dividing the download content in parts and associated each part to specific lambda function
- Kinesis stream:
    - Instead of deserializing the file download in the ingest_data function, lambda should send this file to kinesis stream 
    - Kinesis stream will be responsible for creating multiple records from single file and pass it to firehose delivery
- ECS for analysis:
    - Amazon Elastic Container Service could be used and docker images be packaged as analysi script.
    - Achieved autoscaling without limits of Lambda and cost effective