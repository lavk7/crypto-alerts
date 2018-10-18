provider "aws" {
  region = "ap-southeast-1"
}

// VPC BLOCK
module "vpc" {
  source = "modules/vpc"
}

// LAMBDA BLOCK
module "policy_read_s3" {
  source = "modules/iam_policy"
  name = "UserReadS3"
  actions = ["s3:Get*","s3:List*"]
}

module "policy_firehose_access" {
  source = "modules/iam_policy"
  name = "UserWriteFirehose"
  actions = [
    "firehose:DeleteDeliveryStream",
    "firehose:PutRecord",
    "firehose:PutRecordBatch",
    "firehose:UpdateDestination"
  ]
}

module "access_s3_firehose" {
  source = "modules/iam_role"
  name = "ReadS3AndWriteFirehose"
  services = [
    "lambda.amazonaws.com"
  ]
}

resource "aws_iam_policy_attachment" "attach_s3_policy" {
  name = "attach_s3_policy"
  roles = ["${module.access_s3_firehose.name}"]
  policy_arn = "${module.policy_read_s3.arn}"
}

resource "aws_iam_policy_attachment" "attach_firehose_policy" {
  name = "attach_firehosw_policy"
  roles = ["${module.access_s3_firehose.name}"]
  policy_arn = "${module.policy_firehose_access.arn}"
}

resource "aws_lambda_function" "ingest_data" {
  role = "${module.access_s3_firehose.arn}"
  filename = "ingest.zip"
  function_name = "ingest_data"
  handler = "ingest.lambda_handler"
  runtime = "python3.6"
  source_code_hash = "${base64sha256(file("ingest.zip"))}"
  timeout = 60
}

// REDSHIFT BLOCK

module "redshift" {
  source = "modules/redshift"
  vpc_id = "${module.vpc.vpc_id}"
  igw_id = "${module.vpc.igw_id}"
}

// FIREHOSE BLOCK
resource "aws_s3_bucket" "bucket" {
  bucket = "lk7-firehose-bucket"
  acl    = "private"
}

module "s3ReadWrite" {
  source = "modules/iam_policy"
  name = "S3ReadWriteFirehose"
  actions = [
    "s3:AbortMultipartUpload",        
    "s3:GetBucketLocation",        
    "s3:GetObject",        
    "s3:ListBucket",        
    "s3:ListBucketMultipartUploads",        
    "s3:PutObject"
  ]
  resources = [
    "${aws_s3_bucket.bucket.arn}",
    "${aws_s3_bucket.bucket.arn}/*"
    ]
}

module "invoke_lambda_policy" {
  source = "modules/iam_policy"
  name = "InvokeLambda"
  actions = [
    "lambda:InvokeFunction", 
    "lambda:GetFunctionConfiguration" 
  ]
}

module "cloudwatch_logs_policy" {
  source = "modules/iam_policy"
  name = "RegisterLogs"
  actions = [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents",
    "logs:DescribeLogStreams"
  ]
  resources = ["arn:aws:logs:*:*:*"]


}


module "firehose_iam_role" {
  source = "modules/iam_role"
  name = "FirehoseIamRole"
  services = [
    "firehose.amazonaws.com",
    "lambda.amazonaws.com"
  ]
}

resource "aws_iam_policy_attachment" "attach_s3_policy_firehose" {
  name = "attach_s3_policy_firehoes"
  roles = ["${module.firehose_iam_role.name}"]
  policy_arn = "${module.s3ReadWrite.arn}"
}
resource "aws_iam_policy_attachment" "attach_lambda_policy_firehose" {
  name = "attach_s3_policy_firehoes"
  roles = ["${module.firehose_iam_role.name}"]
  policy_arn = "${module.invoke_lambda_policy.arn}"
}

resource "aws_iam_policy_attachment" "attach_log_policy_firehose" {
  name = "attach_s3_policy_firehoes"
  roles = ["${module.firehose_iam_role.name}"]
  policy_arn = "${module.cloudwatch_logs_policy.arn}"
}
resource "aws_lambda_function" "process_data" {
  role = "${module.firehose_iam_role.arn}"
  filename = "etl.zip"
  function_name = "etl"
  handler = "etl.lambda_handler"
  runtime = "python3.6"
  source_code_hash = "${base64sha256(file("etl.zip"))}"
  timeout = 60
}

resource "aws_kinesis_firehose_delivery_stream" "ingest-stream" {
  name        = "ingest-stream"
  destination = "redshift"


  s3_configuration {
    role_arn           = "${module.firehose_iam_role.arn}"
    bucket_arn         = "${aws_s3_bucket.bucket.arn}"
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
    

  }

  redshift_configuration {
    role_arn           = "${module.firehose_iam_role.arn}"
    cluster_jdbcurl    = "jdbc:redshift://${module.redshift.endpoint}/${module.redshift.database_name}"
    username           = "${module.redshift.master_username}"
    password           = "${module.redshift.master_password}"
    data_table_name    = "ethusdt"
    data_table_columns = "data,high,low,\"open\",close,volume,quoteVolume,weightedAverage"
    s3_backup_mode     = "Disabled"
        processing_configuration = [
      {
        enabled = "true"
        processors = [
          {
            type = "Lambda"
            parameters = [
              {
                parameter_name = "LambdaArn"
                parameter_value = "${aws_lambda_function.process_data.arn}:$LATEST"
              }
            ]
          }
        ]
    }
  ]
  }
  }