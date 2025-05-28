provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name      = "main-vpc"
    owner     = "tim@mondoo.com"
    yor_name  = "main"
    yor_trace = "c50e009f-c671-4d19-84f2-c55b3ced8a45"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name      = "main-subnet"
    owner     = "tim@mondoo.com"
    yor_name  = "main"
    yor_trace = "4ea89d45-bc28-4b6a-a328-76997a50324f"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name      = "main-gw"
    owner     = "tim@mondoo.com"
    yor_name  = "gw"
    yor_trace = "882a779e-4048-40c2-87c0-63d91807eb90"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name      = "main-rt"
    owner     = "tim@mondoo.com"
    yor_name  = "rt"
    yor_trace = "7503293c-5c9d-4e00-b3ed-90a33b6fdabd"
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
    Name      = "ec2-sg"
    owner     = "tim@mondoo.com"
    yor_name  = "ec2_sg"
    yor_trace = "00cd2aa2-2bb2-46dd-af3d-595f954e1ec1"
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
    Name      = "ubuntu-24.04"
    owner     = "tim@mondoo.com"
    yor_name  = "ubuntu"
    yor_trace = "6250cd50-f000-4778-a1e0-ecd2c7ee3f2f"
  }
}
