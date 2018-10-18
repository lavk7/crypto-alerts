# Production Ready system
## Production Ready Real time system
- Store the latest filename and date of the last record in dynamodb
- Get the latest filename and date from dynamodb using lambda function
- Since data is updated every 5 min, get the last file from source again.
- Compare if new data is update
- Update the pointers in Dynamodb
- Send data to firehose
- On SuccessDeliverToRedshift from firehose, trigger the lambda function to execute query to unload using cloudwatch event
- On SuccessfullUnload to S3 from Redshift, trigger the lambda function that will pull the data from s3 and use KPL library to send the data to the Kinesis stream. ( lambda will be fanned out to support larger datasize)
- Kinesis stream will consumed by containers in ECS which will have a task definition. Each container will have seperate analysis script.
- Now for notification module, as soon as there is fluctuation >0.5% , the ECS container will send the message to the topic of SNS to produce notification.

Reference : [img](da-production-ready.png)