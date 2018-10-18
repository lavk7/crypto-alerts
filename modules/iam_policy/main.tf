provider "aws" {
  region = "ap-southeast-1"
}
resource "aws_iam_policy" "policy" {
  name        = "${var.name}"
  path        = "/"
  description = "${var.description}"

  policy = "${data.aws_iam_policy_document.policy_document.json}"
}


data "aws_iam_policy_document" "policy_document" {
  statement {

    actions = "${var.actions}"

    resources = ["${var.resources}"]

    effect = "Allow"
  }
}

output "id" {
  value = "${aws_iam_policy.policy.id}"
}

output "arn" {
  value = "${aws_iam_policy.policy.arn}"
}

output "document" {
  value = "${data.aws_iam_policy_document.policy_document.json}"
}