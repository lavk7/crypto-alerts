# Architecture Design Process
## Design plan:
- Gather the requirements of the system
    - Crypto alert system
    - Alert user when the fluctuation >=0.5% 
- Analyze the desired system characterstics
    - Low latency
    - Highly available
    - Scalable
- Note down the modules
    - Data Ingestion : Responsible for ingesting the data, can be from MULTIPLE resources
    - Data Analysis  : Responsible for comparing the data, should be scalable
    - Notificatin module : Receive alert from Data Analysis module and send it to multiple consumers 
- Data Ingestion:
    - Two function : Pull data, Deliver to Data Store
        - Pull Data: 
            - All data is pulled at once and delivered to DataStore
            - Requirement is highly scalable and cost effective
            - Instead of running the EC2 instance, better use Lambda to cut cost.
            - Pros: Less Cost and Highly Available 
            - Cons: 
                - Ephemeral disk Limit to 512 MB, means cannot download data all at once. This con would be eliminated in case the system is real time, as then the data will be downloaded at specific time intervals, for example every 5 minutes.
                - Time limit of 15 minutes. So if data is very large, the lambda function will fail.
        - Deliver to Data Store:
            - The data received should be delivered easilyt to  DataStore with low latency without much implementation overhead
            - The data received can be transformed easily to compatible format of Datastore
            - Kinesis firehose provides function to easily do Extract Transform Load to Datastore
            - We can also use Kinesis stream followed by Kinesis Firehose if the ingestion is real time.
    Design: To pull data use a lambda function from the source and deliver data to firehose delivery stream

- Data Store:
    - Data will be delivered from DI module to this datastore
    - Data will be extracted to Data Analysis Module from this Datastore
    - At first, dynamodb would have been thought as a good option, as it eliminates the Single point of failure and is truly serverless. But it would be difficult to achieve low latency for the system for complex queries.
    - Since Data Analysis module need to handle other analysis scripts in future and data can be huge, it is better to go with AWS Redshift.
        - Pros: It is scalable and can give result of complex queries on large data with low latency. 
        - Cons: Induces Single Point of Failure to system. Also resizing operations have to managed by user now instead of amazon.
    Design: Create a cluster of Redshift with two nodes of r4.8xlarge to provide optimal performance

- Data Analysis Module:
    - Function: Get data from datastore & Run analysis script comparing the two data
    - Requirement is that new scripts can be introduced for analysing.
    - Trigger method: when the datastore has completed data from DI module
        - Create a cloudwatch notification event of Delivery finished and invoke the event to trigger the analysis in correspondance to this event
    - Analysis Method:
        - Since analysis is event driven, it is again better to use lambda instead of EC2 instance to cut costs and provide availability.
        - Also using lambda it would be easy to add new analysis scripts by just creating new lambda function for each script.
    - Design: Use lambda to pull data from Datastore and run analysis script. If fluctuation > 0.5% happens with previous data, send an api call to notification module.
        - Pros:
            - Scalable with new analysis scripts
          Cons: 
            - Time limit 15min and Memery 3008 mb

