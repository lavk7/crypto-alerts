# Implementation

## Plan:
    - Create lambda function, for pulling data
        - ingest_data:
          get all files from source
    - Create redshift cluster for datastore `crypt-data`
    - Create table for putting data `ethusdt`
    - Create lambda function to take the records and transform `etl`
    - Create s3 bucket for intermediate storing of data
    - Create Firehose delivery stream using `etl` and  `crypt-data`
    - Update the ingest_data function to send the file to redshift delivery


## Step 1: Implement lambda function
- using botocore3
- get files using botocore3 client
- Read files as bytes
- Prepare bytes object to transfer
- Test whether files are able to download
- Add IAM role to get ReadAccess to S3
`ERR: Timeout need to be increased`

## Step 2: Redshift cluster
- Created most generalized redshift cluster also creating the redshift-subnet group.
- Trying to test by creating a table using table query
`ERR: Minimum dc2.large needed for query editor. Resizing to dc2.large`
- Try to create a sample table. Table is created.

## Step 3: Create ETL lambda function
- Using exising blue print for processing json

## Step 4: Create S3 bucket
- Create a bucket with unique name

## Step 5: Create firehose delivery
- Configure destination as redshift and enter db details
- Processor as lambda `etl` function
- S3 bucket as above
- Created role FirehoseIamRole with policies 
    - InvokeLambda
    - S3ReadWriteFirehose
    Assumed by firehose.amazonaws.com and  lambda.amazonaws.com   

## Step 6: Send data from funciton ingest_data to firehose
- Update python function



# Errs
- Missed adding the log access for Firehose. Add `RegisterLogs` policy to FirehoseIamRole

- I assumed firehose support one to many mapping while transforming the data and delivering it Redshift. It turns out it is One to One,  one record in and one record out. 

- Redshift cannot be accessed from firehose. Redshift needs to be publicly accessible. Cannot be accessed from firehose after checking the cloudwatch logs
    - Created internet gateway
    - Added  to  routing table and associate with redshift subnet

- Transformed data is coming to S3, but not delivering to Redshift
    - Checked stl_load_error and found delimiter not found
    - Since the output format is json, use `json auto` in copy options

- Authorization problem in Redshift logs.
    - Tried to run copy command manually, the vitalik user cannot assume role of FirehoseIamRole
    - Add the IAM role to redshift cluster solves the issue.















## Roles and Policy
- For `ingest_data` lambda function:
    - Role: ReadS3AndWriteFirehose
    - Assumed by: lambda.amazonaws.com
    - Policies:
        - UserReadS3
        - UserWriteFirehose

- For Kinesis Firehose and etl lambda:
    - Role: FirehoseIamRole
    - Assumed by : 
        - "firehose.amazonaws.com",
        - "lambda.amazonaws.com",
        - "redshift.amazonaws.com"
    - Policies: 
        - RegisterLogs
        - InvokeLambda
        - S3ReadWriteFirehose
