import boto3
import botocore
import os
import base64
import json
import traceback

BUCKET_NAME = 'tgr-hire-devops-test' # replace with your bucket name
#DIR=''
s3 = boto3.resource('s3')
bucket = s3.Bucket(BUCKET_NAME)

def download_dir(client,firehoseclient, resource, dist, local, bucket):
    paginator = client.get_paginator('list_objects')
    for result in paginator.paginate(Bucket=bucket, Delimiter='/', Prefix=dist):
        if result.get('CommonPrefixes') is not None:
            for subdir in result.get('CommonPrefixes'):
                download_dir(client, firehoseclient, resource, subdir.get('Prefix'), local, bucket)
        if result.get('Contents') is not None:
            result.get('Contents')
            for file in result.get('Contents'):
                if not os.path.exists(os.path.dirname(local + os.sep + file.get('Key'))):
                     os.makedirs(os.path.dirname(local + os.sep + file.get('Key')))
                try:
                    resource.meta.client.download_file(bucket, file.get('Key'), local + os.sep + file.get('Key'))
                    with open(local + os.sep + file.get('Key'), 'r') as f:
                        blob = f.read()
                        pricelist = json.loads(blob)
                        for i in range(0, len(pricelist), 500):
                            recordlist = []
                            for j in range(0,499):
                                recordlist.append({
                                    'Data': json.dumps(pricelist[i+j])
                                })
                            firehoseclient.put_record_batch(
                                DeliveryStreamName = "ingest-stream",
                                Records = recordlist
                            )    
                except Exception as e:
                    print(e)
                    pass
def lambda_handler(event,context):
    s3client = boto3.client('s3')
    resource = boto3.resource('s3')
    firehoseclient = boto3.client('firehose')
    download_dir(s3client,firehoseclient, resource, 'crypto/01-data-ingestion', '/tmp', 'tgr-hire-devops-test')

if __name__ == '__main__':
    lambda_handler(None, None)
