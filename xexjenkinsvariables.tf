# Specify the AMI (Amazon Machine Image) for the EC2 instance
variable "ami" {
  type    = string
  default = "ami-08541bb85074a743a"
}

# Define the name for the S3 bucket to store Jenkins artifacts
variable "bucket_name" {
  type    = string
  default = "xexconsultancybucket"
}

# Set the AWS region where resources will be created
variable "aws_region" {
  type    = string
  default = "us-west-2"
}

# Specify the EC2 instance type (e.g., t2.micro) for the Jenkins server
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

# Define the name of the AWS key pair used for SSH access to the EC2 instance
variable "key_pair" {
  type    = string
  default = "xexconsultancy2"
}

# Set the allowed CIDR block for SSH access to the security group (sensitive because it's an IP address)
variable "my_ip" {
  type      = string
  default   = "0.0.0.0/0"
  sensitive = true
}
