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

