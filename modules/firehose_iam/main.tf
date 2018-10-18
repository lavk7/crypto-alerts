variable "bucket_arn" {
  
}

module "s3ReadWrite" {
  source = "../iam_policy"
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
    "${var.bucket_arn}",
    "${var.bucket_arn}/*"
    ]
}

module "invoke_lambda_policy" {
  source = "../iam_policy"
  name = "InvokeLambda"
  actions = [
    "lambda:InvokeFunction", 
    "lambda:GetFunctionConfiguration" 
  ]
}

module "cloudwatch_logs_policy" {
  source = "../iam_policy"
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
  source = "../iam_role"
  name = "FirehoseIamRole"
  services = [
    "firehose.amazonaws.com",
    "lambda.amazonaws.com",
    "redshift.amazonaws.com"
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

output "arn" {
  value = "${module.firehose_iam_role.arn}"
}
