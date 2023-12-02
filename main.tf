provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "eu-central-1"
}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

# Публічний сабнет
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Приватний сабнет
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}

# Інтернет-шлюз для публічного сабнету
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# Атачим публічний сабнет до інтернет-шлюзу
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "public_route_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# EC2 і Security Group
resource "aws_instance" "terserver" {
  ami                         = "ami-0669b163befffbdfc"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = "demo"

  vpc_security_group_ids = [aws_security_group.my_sg.id]

  user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install httpd -y 
        sudo systemctl start httpd
        sudo systemctl enable httpd
        sudo echo "<p> Terraform </p>" > /var/www/html/index.html
        EOF

  tags = {
    Name = "my-ec2-instance"
  }
}

resource "aws_security_group" "my_sg" {
  vpc_id      = aws_vpc.my_vpc.id
  name        = "my-security-group"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Підключення до EC2 по SSH
resource "null_resource" "configure_ssh" {
  depends_on = [aws_instance.terserver]
  connection {
    type        = "ssh"
    host        = aws_instance.terserver.public_ip
    user        = "ec2-user"
    private_key = file("C:/Users/dante/Downloads/demo.pem")
  }
}
