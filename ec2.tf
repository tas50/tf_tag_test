provider "aws" {
    region = "us-west-2"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name  = "main-vpc"
        owner = "tim@mondoo.com"
    }
}

resource "aws_subnet" "main" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-west-2a"
    map_public_ip_on_launch = true
    tags = {
        Name  = "main-subnet"
        owner = "tim@mondoo.com"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name  = "main-gw"
        owner = "tim@mondoo.com"
    }
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name  = "main-rt"
        owner = "tim@mondoo.com"
    }
}

resource "aws_route" "internet_access" {
    route_table_id         = aws_route_table.rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "a" {
    subnet_id      = aws_subnet.main.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "ec2_sg" {
    name        = "ec2-sg"
    description = "Allow SSH and ICMP"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name  = "ec2-sg"
        owner = "tim@mondoo.com"
    }
}

data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["099720109477"] # Canonical

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
    }
}

resource "aws_instance" "ubuntu" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t3.micro"
    subnet_id                   = aws_subnet.main.id
    associate_public_ip_address = true
    vpc_security_group_ids      = [aws_security_group.ec2_sg.id]

    root_block_device {
        volume_size = 40
        volume_type = "gp3"
    }

    tags = {
        Name  = "ubuntu-24.04"
        owner = "tim@mondoo.com"
    }
}
