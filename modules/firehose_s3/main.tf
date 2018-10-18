variable "bucket_name" {
  
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}"
  acl    = "private"
  force_destroy = true
}

output "arn" {
  value = "${aws_s3_bucket.bucket.arn}"
}

