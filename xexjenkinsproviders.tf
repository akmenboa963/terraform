# Specify the AMI (Amazon Machine Image) for the EC2 instance
variable "xex_ami" {
  type    = string
  default = "ami-08541bb85074a743a"
}

# Define the name for the S3 bucket to store Jenkins artifacts
variable "xex_bucket_name" {
  type    = string
  default = "xexconsultancybucket"
}

# Set the AWS region where resources will be created
variable "xex_aws_region" {
  type    = string
  default = "us-west-2"
}

# Specify the EC2 instance type (e.g., t2.micro) for the Jenkins server
variable "xex_instance_type" {
  type    = string
  default = "t2.micro"
}

# Define the name of the AWS key pair used for SSH access to the EC2 instance
variable "xex_key_pair" {
  type    = string
  default = "xex_xexconsultancy"
}

# Set the allowed CIDR block for SSH access to the security group (sensitive because it's an IP address)
variable "xex_my_ip" {
  type      = string
  default   = "YOUR_IP_ADDRESS"  # Change this to your actual IP address
  sensitive = true
}
