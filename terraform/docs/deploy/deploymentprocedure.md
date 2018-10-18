# Procedure

## Prerequisites
- Confirm that the AWS access credentials are stored in ~/.aws/credentials. Docker would mount it to the container
- Python3 in installed on the system


## Deployment
- Run `cryptoalert.sh -s $BUCKET_NAME deploy` to deploy. $BUCKET_NAME should be unique and not existing.
- Create table on redshift by running following in query with follwing details.
    - Authentication :
    ```
    User: vitalik
    Password: Vitalik22
    Database: mydb
    ```
    - Query: 
    ```
    create table ethusdt (
    date float8,
    high float8,
    low float8,
    "open" float8,
    close float8,
    volume float8,
    quoteVolume float8,
    weightedAverage float8
)
    ```
- Execute the lambda function `ingest_data`:
    - Configure test event
    - Set context as empty object {}
    - Press test

- Confirm that the `ingest_data` function executed successfully.
    - Ignore error `[Errno 20] Not a directory: '/tmp/crypto/01-data-ingestion/.EE7023d3' -> '/tmp/crypto/01-data-ingestion/'` due to incompatible data

- Confirm the firehose transmission by checking the log of the transformation lambda function `etl`

- Wait for few minutes and check the table `ethusdt` table in redshift cluster `crypto-data` 

## Update 
If any update in terraform file, run `./cryptalert.sh update`
`Note: In case of change in python code, run deploy again`

## Destroy
- Delete s3 bucket 
To destroy run `./cryptoalert.sh destroy`

# Troubleshooting
- By chance if .terraform or .tfstate files got removed, the infrastructure has to be destoyed manually in following order:
    - Redshift
    - Redshift subnetgroup `redshift-sbunet`
    - S3 Bucket
    - Firehose
    - Lambda `etl` and `ingest_data`
    - IAM Policies 
        - UserReadS3
        - UserWriteFirehose
        - attach_s3_policy
        - attach_firehosw_policy
        - S3ReadWriteFirehose
        - InvokeLambda
        - RegisterLogs
    - IAM Roles
        - FirehoseIamRole
        - ReadS3AndWriteFirehose
    - VPC