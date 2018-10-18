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
  firehose_role = "${module.firehose_iam_role.arn}"
}

// FIREHOSE S3 BUCKET
module "firehose_s3" {
  source = "modules/firehose_s3"
  
}


// FIREHOSE IAM ROLE
module "firehose_iam_role" {
  source = "modules/firehose_iam"
  bucket_arn = "${module.firehose_s3.arn}"
}

// FIREHOSE LAMBDA 
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
    bucket_arn         = "${module.firehose_s3.arn}"
    buffer_size        = 10
    buffer_interval    = 400
  }

  redshift_configuration {
    role_arn           = "${module.firehose_iam_role.arn}"
    cluster_jdbcurl    = "jdbc:redshift://${module.redshift.endpoint}/${module.redshift.database_name}"
    username           = "${module.redshift.master_username}"
    password           = "${module.redshift.master_password}"
    copy_options       = "json 'auto'"
    data_table_name    = "ethusdt"
    data_table_columns = "date,high,low,\"open\",close,volume,quoteVolume,weightedAverage"
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