variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_name" {}
 
variable "aws_region" {
    default = "ap-northeast-1"
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region     = "${var.aws_region}"
}


resource "aws_vpc" "tf_vpc" {
    cidr_block = "10.10.0.0/16"
    instance_tenancy     = "default"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags {
        Name = "tf_vpc"
    }
}

resource "aws_subnet" "public_web1" {
    vpc_id                  = "${aws_vpc.tf_vpc.id}"
    cidr_block              = "10.10.1.0/24"
    availability_zone       = "ap-northeast-1a"
    map_public_ip_on_launch = false
    tags {
        Name = "tf_public_web1"
    }
}

resource "aws_subnet" "public_web2" {
    vpc_id                  = "${aws_vpc.tf_vpc.id}"
    cidr_block              = "10.10.2.0/24"
    availability_zone       = "ap-northeast-1c"
    map_public_ip_on_launch = false
    tags {
        Name = "tf_public_web2"
    }
}

resource "aws_subnet" "private_db1" {
    vpc_id                  = "${aws_vpc.tf_vpc.id}"
    cidr_block              = "10.10.3.0/24"
    availability_zone       = "ap-northeast-1a"
    tags {
        Name = "tf_private_db1"
    }
}

resource "aws_subnet" "private_db2" {
    vpc_id                  = "${aws_vpc.tf_vpc.id}"
    cidr_block              = "10.10.4.0/24"
    availability_zone       = "ap-northeast-1c"
    tags {
        Name = "tf_private_db2"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.tf_vpc.id}"
    tags {
        Name = "tf-gw"
    }
}

resource "aws_route_table" "public_rtb" {
    vpc_id = "${aws_vpc.tf_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
    tags {
        Name = "tf_rtb"
    }
}

resource "aws_route_table_association" "public_1" {
    subnet_id      = "${aws_subnet.public_web1.id}"
    route_table_id = "${aws_route_table.public_rtb.id}"
}

resource "aws_route_table_association" "public_2" {
    subnet_id      = "${aws_subnet.public_web2.id}"
    route_table_id = "${aws_route_table.public_rtb.id}"
}

resource "aws_security_group" "app" {
    name        = "tf_web"
    description = "It is a security group on http of tf_vpc"
    vpc_id      = "${aws_vpc.tf_vpc.id}"
    tags {
        Name = "tf_web"
    }
}
 
resource "aws_security_group_rule" "ssh" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.app.id}"
}
 
resource "aws_security_group_rule" "web" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.app.id}"
}
 
resource "aws_security_group_rule" "all" {
    type              = "egress"
    from_port         = 0
    to_port           = 65535
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.app.id}"
}

resource "aws_instance" "web1" {
    ami                         = "ami-56d4ad31"
    instance_type               = "t2.micro"
    key_name                    = "${var.aws_key_name}"
    vpc_security_group_ids      = ["${aws_security_group.app.id}"]
    subnet_id                   = "${aws_subnet.public_web1.id}"
    associate_public_ip_address = "false"
    root_block_device = {
        volume_type = "gp2"
        volume_size = "20"
    }
    ebs_block_device = {
        device_name = "/dev/sdf"
        volume_type = "gp2"
        volume_size = "100"
    }
    tags {
        Name = "tf_instance"
    }
}

resource "aws_eip" "web1" {
  instance = "${aws_instance.web1.id}"
  vpc      = true
}

resource "aws_instance" "web2" {
    ami                         = "ami-56d4ad31"
    instance_type               = "t2.micro"
    key_name                    = "nao-key"
    vpc_security_group_ids      = ["${aws_security_group.app.id}"]
    subnet_id                   = "${aws_subnet.public_web2.id}"
    associate_public_ip_address = "false"
    root_block_device = {
        volume_type = "gp2"
        volume_size = "20"
    }
    ebs_block_device = {
        device_name = "/dev/sdf"
        volume_type = "gp2"
        volume_size = "100"
    }
    tags {
        Name = "tf_instance"
    }
}

resource "aws_eip" "web2" {
  instance = "${aws_instance.web2.id}"
  vpc      = true
}

output "elastic_ip_of_web1" {
    value = "${aws_eip.web1.public_ip}"
}

output "elastic_ip_of_web2" {
    value = "${aws_eip.web2.public_ip}"
}

