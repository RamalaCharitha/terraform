# 1. Configure the AWS Provider with direct credentials
provider "aws" {
  region     = "us-east-1"
  access_key = ${{ secrets.AWS_ACCESS_KEY_ID }}
  secret_key = ${{ secrets.AWS_SECRET_ACCESS_KEY }}
}

# 2. Create the EC2 Instance
resource "aws_instance" "simple_ec2" {
  ami           = "ami-04b70fa74e45c3917" # Standard Ubuntu 24.04 AMI in us-east-1
  instance_type = "t2.micro"

  tags = {
    Name = "Harness-IaCM-Demo"
  }
}
