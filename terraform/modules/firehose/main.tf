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

resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "terraform-kinesis-firehose-test-stream"
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