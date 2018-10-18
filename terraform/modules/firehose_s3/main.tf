
resource "aws_s3_bucket" "bucket" {
  bucket = "lk7-firehose-bucket"
  acl    = "private"
  force_destroy = true
}

output "arn" {
  value = "${aws_s3_bucket.bucket.arn}"
}

