# Configure the AWS provider
provider "aws" {
  region = "us-east-1" # Change this to your desired AWS region
}

# Fetch the default VPC information
data "aws_vpc" "default" {
  default = true
}

# Fetch the default VPC subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create security groups
resource "aws_security_group" "allow_8080_and_all" {
  name        = "xexconsultancyecommerce-allow_8080_and_all"
  description = "Allow traffic on port 8080 and all inbound/outbound traffic"

  # Allow inbound traffic on port 8080
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all inbound traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_http" {
  name        = "xexconsultancyecommerce-allow_http"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

# Create launch configuration for the webserver
resource "aws_launch_configuration" "webserver" {
  name          = "xexconsultancyecommerce-webserver"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  security_groups = [
    aws_security_group.allow_http.id,
    aws_security_group.allow_8080_and_all.id,
  ]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd aws-cli
    systemctl start httpd
    systemctl enable httpd
    echo "Welcome to XEX Consultancy eCommerce!" > /var/www/html/index.html
    aws s3 cp /var/log/user-data.log s3://xexconsultancyecommerce/user-data-logs/instance-\$(date -u +"%Y-%m-%dT%H-%M-%SZ").log
  EOF
}

# Create a target group for the ALB for xexconsultancyecommerce
resource "aws_lb_target_group" "xexconsultancyecommercetg" {
  name     = "xexconsultancyecommercetg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  # Add any other necessary configuration for the target group
  # ...
}

# Create Auto Scaling group for the webserver
resource "aws_autoscaling_group" "webserver" {
  name                 = "xexconsultancyecommerce-webserver"
  desired_capacity     = 3
  min_size             = 3
  max_size             = 5
  vpc_zone_identifier  = data.aws_subnets.default.ids
  launch_configuration = aws_launch_configuration.webserver.name
  target_group_arns    = [aws_lb_target_group.xexconsultancyecommercetg.arn]

}

# Fetch the Amazon Linux 2 AMI information
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  owners = ["amazon"]
}

# Create an S3 bucket for the backend
resource "aws_s3_bucket" "backend" {
  bucket = "xexconsultancyecommerce-backend"
}

resource "aws_lb" "alb" {
  name               = "xexconsultancyecommerce-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
}

# Configure the ALB to route traffic to the Target Group for xexconsultancyecommerce
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.xexconsultancyecommercetg.arn
  }
}

# Create security group for ALB
resource "aws_security_group" "xex-consultancy-ecommerce-alb-sg" {
  # Set name and description of the security group
  name        = "xex-consultancy-ecommerce-alb-sg"
  description = "Security group for XEX Consultancy E-commerce ALB"

  # Set the VPC ID where the security group will be created
  vpc_id     = data.aws_vpc.default.id
  depends_on = [data.aws_vpc.default]

  # Inbound Rule
  # Allow HTTP access from anywhere
  ingress {
    description = "Allow HTTP Traffic"
    from_port   = 80 # Assuming HTTP uses port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing access from any IP
  }

  # Inbound Rule
  # Allow HTTPS access from anywhere
  ingress {
    description = "Allow HTTPS Traffic"
    from_port   = 443 # Assuming HTTPS uses port 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing access from any IP
  }

  # SSH access from specific IP range (replace with your specific IP or range)
  ingress {
    description = "Allow SSH Traffic"
    from_port   = 22 # Assuming SSH uses port 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound Rule
  # Allow all egress traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Set tags for the security group
  tags = {
    Name = "XEX Consultancy E-commerce ALB SG"
  }
}
