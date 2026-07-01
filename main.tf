provider "aws" {
  region = "us-east-1"
}

# 1. Generate a secure, dynamic private key
resource "tls_private_key" "dynamic_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Register the public key with AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "harness-tomcat-key"
  public_key = tls_private_key.dynamic_key.public_key_openssh
}

# 3. Define the Security Group (Exposing Web Port 8080)
resource "aws_security_group" "allow_ssh_and_tomcat" {
  name        = "tomcat-ec2-security-group"
  description = "Allow SSH and Tomcat web traffic"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "Tomcat Web Server Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Anyone can view your app via the public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Define the EC2 Instance (With Automatic Tomcat Installation)
resource "aws_instance" "tomcat_node" {
  ami                         = "ami-08f44e8eca9095668" # Amazon Linux 2023
  instance_type               = "c7i-flex.large"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_and_tomcat.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name

  # Automation sequence to install Java and Tomcat
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # 1. Update system libraries and install Java 17 (Required for Tomcat 10)
              dnf update -y
              dnf install -y java-17-amazon-corretto-headless

              # 2. Download and unpack Apache Tomcat 10
              cd /opt
              curl -LO "https://apache.org"
              tar -xf apache-tomcat-10.1.25.tar.gz
              mv apache-tomcat-10.1.25 tomcat
              rm -f apache-tomcat-10.1.25.tar.gz

              # 3. Secure folder permissions for ec2-user ownership
              chown -R ec2-user:ec2-user /opt/tomcat
              chmod +x /opt/tomcat/bin/*.sh

              # 4. Run Tomcat directly under the ec2-user profile context
              sudo -i -u ec2-user /opt/tomcat/bin/startup.sh
              EOF

  tags = {
    Name = "Harness-Tomcat-Node"
  }
}

# 5. Output the Public IP to check the web browser dashboard
output "instance_public_ip" {
  value       = aws_instance.tomcat_node.public_ip
  description = "The public IP of the Tomcat server"
}
