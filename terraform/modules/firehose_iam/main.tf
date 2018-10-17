resource "aws_s3_bucket" "bucket" {
  bucket = "lk7-firehose-bucket"
  acl    = "private"
}

module "s3ReadWrite" {
  source = "../modules/iam_policy"
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
  source = "../modules/iam_policy"
  name = "InvokeLambda"
  actions = [
    "lambda:InvokeFunction", 
    "lambda:GetFunctionConfiguration" 
  ]
}

module "cloudwatch_logs_policy" {
  source = "../modules/iam_policy"
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
  source = "../modules/iam_role"
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

output "role_arn" {
  value = "${module.firehose_iam_role.arn}"
}
