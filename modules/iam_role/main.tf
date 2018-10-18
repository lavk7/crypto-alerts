resource "aws_iam_role" "role" {
    name = "${var.name}"
    assume_role_policy = "${data.aws_iam_policy_document.policy_document.json}"
}

data "aws_iam_policy_document" "policy_document" {
    statement {
    actions = ["sts:AssumeRole"]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = "${var.services}"
    }
    
  }
}

output "name" {
    value = "${var.name}"
}

output "arn" {
    value = "${aws_iam_role.role.arn}"
}