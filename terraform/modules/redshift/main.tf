resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier = "crypto-data-cluster"
  database_name      = "mydb"
  master_username    = "vitalik"
  master_password    = "Vitalik22"
  node_type          = "dc2.large"
  cluster_type       = "single-node"
  cluster_subnet_group_name = "${aws_redshift_subnet_group.redshift_subnet_group.name}"
  vpc_security_group_ids = ["${aws_security_group.redshift_access.id}"]
  final_snapshot_identifier = "final-backup-redshift"
}

resource "aws_subnet" "private_subnet" {
  cidr_block        = "10.1.2.0/24"
  availability_zone = "ap-southeast-1a"
  vpc_id            = "${var.vpc_id}"

  tags {
    Name = "redshift-subnet"
  }
}

resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "redshift-subnet"
  subnet_ids = ["${aws_subnet.private_subnet.id}"]
}

resource "aws_security_group" "redshift_access" {
  vpc_id = "${var.vpc_id}"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "-1"
    from_port = 0
    to_port = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "-1"
    from_port = 0
    to_port = 0
  }
  
}

resource "aws_route_table" "igw-route-table" {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.igw_id}"
  }
  vpc_id = "${var.vpc_id}"
}

resource "aws_route_table_association" "route_associate" {
  route_table_id = "${aws_route_table.igw-route-table.id}"
  subnet_id = "${aws_subnet.private_subnet.id}"
}

output "database_name" {
  value = "${aws_redshift_cluster.redshift_cluster.database_name}"
}

output "endpoint" {
  value = "${aws_redshift_cluster.redshift_cluster.endpoint}"
}

output "master_username" {
  value = "vitalik"
}

output "master_password" {
  value = "Vitalik22"
}

output "cluster-identifier" {
  value = "${aws_redshift_cluster.redshift_cluster.cluster_identifier}"
}



