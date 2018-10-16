resource "aws_vpc" "vpc" {
  cidr_block = "10.1.0.0/16"
}


resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}
