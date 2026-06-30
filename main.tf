provider "aws" {
  region = "us-east-1"
}

# 1. Define the Security Group
resource "aws_security_group" "allow_ssh_and_k8s" {
  name        = "minikube-ec2-security-group"
  description = "Allow SSH and application traffic"

  ingress {
    description = "SSH from everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Define the EC2 Instance
resource "aws_instance" "kubernetes_node" {
  ami                         = "ami-08f44e8eca9095668" # Amazon Linux 2023 AMI in us-east-1
  instance_type               = "c7i-flex.large"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_and_k8s.id]
  associate_public_ip_address = true

  # User Data script executed automatically at system startup
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # 1. Update system and install Docker
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker

              # 2. Add ec2-user to the docker group
              usermod -aG docker ec2-user

              # 3. Install Kubectl (Cleaned URL without nested commands)
              curl -LO "https://k8s.io"
              install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

              # 4. Install Minikube (Cleaned flat URL configuration)
              curl -LO "https://googleapis.com"
              install minikube-linux-amd64 /usr/local/bin/minikube

              # 5. Switch to ec2-user to start Minikube
              sudo -i -u ec2-user minikube start --driver=docker
              EOF

  tags = {
    Name = "Harness-Minikube-Via-UserData"
  }
}

# 3. Output the public IP address
output "instance_public_ip" {
  value       = aws_instance.kubernetes_node.public_ip
  description = "The public IP of the newly created EC2 instance"
}
