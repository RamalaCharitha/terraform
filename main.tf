# 1. Configure the AWS Provider with direct credentials
provider "aws" {
  region     = "us-east-1"
 
}

# 2. Create the EC2 Instance
resource "aws_instance" "simple_ec2" {
  ami           = "ami-08f44e8eca9095668" # Standard Ubuntu 24.04 AMI in us-east-1
  instance_type = "t3.micro"

  tags = {
    Name = "Harness-IaCM-Demo"
  }
}
