provider "aws" {
  region = "us-east-1"
}

# 1. Generate a secure, dynamic private key
resource "tls_private_key" "dynamic_key" {
  algorithm = "RSA"
  rsa_bits  = 4009
}

# 2. Register the public key with AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "harness-minikube-key"
  public_key = tls_private_key.dynamic_key.public_key_openssh
}

# 3. Define the Security Group
resource "aws_security_group" "allow_ssh_and_k8s" {
  name        = "minikube-ec2-security-group"
  description = "Allow SSH and traffic"

  ingress {
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

# 4. Define the EC2 Instance (Now linked to the dynamic key)
resource "aws_instance" "kubernetes_node" {
  ami                         = "ami-08f44e8eca9095668" # Amazon Linux 2023
  instance_type               = "c7i-flex.large"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_and_k8s.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name # Linked here

  tags = {
    Name = "Harness-Minikube-Node"
  }
}

# 5. Output the Public IP
output "instance_public_ip" {
  value       = aws_instance.kubernetes_node.public_ip
  description = "The public IP of the instance"
}

# 6. Output the Private Key dynamically for Harness to read
output "generated_private_key" {
  value     = tls_private_key.dynamic_key.private_key_pem
  sensitive = true
}
