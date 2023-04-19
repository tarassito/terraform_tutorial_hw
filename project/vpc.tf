resource "aws_vpc" "ucu-vpc" {
  cidr_block           = "10.0.0.0/24"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "ucu-vpc"
  }
}

resource "aws_subnet" "ucu-subnet-1" {
  vpc_id            = aws_vpc.ucu-vpc.id
  cidr_block        = "10.0.0.0/26"
  availability_zone = "us-west-2c"
}

resource "aws_subnet" "ucu-subnet-2" {
  vpc_id            = aws_vpc.ucu-vpc.id
  cidr_block        = "10.0.0.64/26"
  availability_zone = "us-west-2d"
}

resource "aws_security_group" "ucu-security-group" {
  name_prefix = "ucu_sg"
  vpc_id      = aws_vpc.ucu-vpc.id

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self      = true
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_db_subnet_group" "ucu-subnet-group" {
  name       = "ucu-subnet-group"
  subnet_ids = [aws_subnet.ucu-subnet-1.id, aws_subnet.ucu-subnet-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_internet_gateway" "ucu-ig" {
  vpc_id = aws_vpc.ucu-vpc.id
  tags = {
    Name = "ucu-ig"
  }
}


