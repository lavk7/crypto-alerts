resource "aws_s3_bucket" "bucket" {
  bucket = "lk7-firehose-bucket"
  acl    = "private"
}
