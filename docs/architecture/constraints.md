# Constraints for current architecture
## Specs
### Data Ingestion Module
- Lambda:
    - Lambda: Does not support ingestion on real time trading prices
    - Lambda: The current ingest_data function only support data of small size as the file is being store in docker container itself with ephimeral storage of 512 mb
    - Lambda: If the latency of the source is very high, it might be possible that ingest_data lambda function might take even more than 15 mins
    - Lambda: For a new type of source, a new function have to developed for pulling data as the file is parsed and each entry is then converted to a record. Also, the transformation has to be done on the new format of data. So overall, for new source we would have to add atleast two more lambda function which isn't kind of scalable that we might expect our architecture to be. 
- Redshift:
    - Redshift : scalability causes a downtime which is generaly few minutes. Also, during copying data of new nodes, Redshift cluster will be running in Read Only mode.
    - Redshift: Induced Single point of failure. 
    - Redshift: Total number of databases should be less than 60
    - Maximum number of concurrent users can be 500
    - A single row in any table cannot be more than 4mb
    - No suport of multi AZ deployments
    - Redshift enforces a query concurrency limit of 15 on a cluster and total 8 queues. That means the management of fast running query and slow query will not be managed by AWS.
- Firehose:
    - The maximum data size that can be sent to Firehose Delivery stream is 1000 kb
    - Redshift has to be publicly accessible so that Firehose can deliver data to Redshift 

### Data Analysis module
- Lambda:
    - Time limit of 15 minutes for an analysis script
    - Memory limit of 3008 mb


### Conclusions
- System cannot handle real time data
- System will fail if data is large
- We have to be careful while managing Redshift
- Long running analysis scripts can cause failure
- Redshift is Single point of failure