# Set up the AWS provider with the specified region
provider "aws" {
  region = var.aws_region
}

# Generate a TLS private key for SSH access to EC2 instances
resource "tls_private_key" "xexconsultancy_key" {
  algorithm = "RSA"
}

# Create a local file for the private key in PEM format
resource "local_file" "private_key_pem" {
  filename = "private_key.pem"
  content  = tls_private_key.xexconsultancy_key.private_key_pem
}

# Create another local file for the private key with a custom filename
resource "local_file" "private_key_pem" {
  content  = tls_private_key.xexconsultancy_key.private_key_pem
  filename = "${var.key_pair}.pem"
}

# Create an IAM role for EC2 instances
resource "aws_iam_role" "xexconsultancy_ec2_role" {
  name = "xexconsultancy_ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach the IAM role to an instance profile
resource "aws_iam_instance_profile" "xexconsultancy_instance_profile" {
  name = "xexconsultancy_instance_profile"
  role = aws_iam_role.xexconsultancy_ec2_role.name
}

# Create an EC2 instance for Jenkins
resource "aws_instance" "xexconsultancy_jenkins_server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_pair # Use the key pair name without the .pem extension
  vpc_security_group_ids = [aws_security_group.xexconsultancy_jenkins_server_sg.id]
  user_data              = <<EOF
#!/bin/bash
yum update -y
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install java-11-amazon-corretto -y
yum install jenkins -y
systemctl enable jenkins
systemctl start jenkins
EOF
  iam_instance_profile   = aws_iam_instance_profile.xexconsultancy_instance_profile.name
  tags = {
    Name = "xexconsultancy_Jenkins_Server"
  }
}

# Create a security group for the EC2 instance
resource "aws_security_group" "xexconsultancy_jenkins_server_sg" {
  name        = "xexconsultancy_jenkins_server_inbound"
  description = "Allow SSH and access to port 8080"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Create an S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "xexconsultancy_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Define an IAM policy to grant read and write access to the S3 bucket
resource "aws_iam_role_policy" "xexconsultancy_jenkins_policy" {
  name = "xexconsultancy_jenkins_policy"
  role = aws_iam_role.xexconsultancy_ec2_role.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PerformBucketActions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

# Create an AWS key pair using the generated PEM private key
resource "aws_key_pair" "xexconsultancy" {
  key_name   = var.key_pair
  public_key = tls_private_key.xexconsultancy_key.public_key_openssh
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}
