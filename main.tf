provider "aws" {
  region = "eu-central-1" # AWS region set to Frankfurt, Germany
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" # Define the CIDR block for the VPC
  # This creates a Virtual Private Cloud (VPC) to isolate resources in the AWS network.
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.main.id # Associate the subnet with the created VPC
  cidr_block        = "10.0.1.0/24"   # Define the CIDR block for the subnet
  availability_zone = "eu-central-1a" # Specify the availability zone for the subnet
  # This creates a subnet within the VPC for hosting resources.
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id # Attach the internet gateway to the VPC
  # This creates an Internet Gateway to allow internet access for resources in the VPC.
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  # This creates a route table for managing network traffic within the VPC.
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP/32"] # Replace with your IP for SSH access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe01e" # Replace with correct AMI for your region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_subnet.id
  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF
}

resource "aws_db_instance" "ecommerce_db" {
  allocated_storage    = 20
  engine             = "mysql"
  engine_version     = "8.0"
  instance_class     = "db.t2.micro"
  name               = "ecommerce"
  username           = "admin"
  password           = "jedi23" # Change this
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  skip_final_snapshot = true
}

resource "aws_db_subnet_group" "default" {
  name       = "default"
  subnet_ids = [aws_subnet.my_subnet.id]
}

resource "aws_s3_bucket" "product_images" {
  bucket = "my-ecommerce-product-images-bucket" # Change to a unique name
  acl    = "private"
}

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "database_endpoint" {
  value = aws_db_instance.ecommerce_db.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.product_images.bucket
}

  }
}