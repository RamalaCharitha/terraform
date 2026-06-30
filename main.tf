provider "aws" {
  region = "us-east-1"
}

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

resource "aws_instance" "kubernetes_node" {
  ami                         = "ami-08f44e8eca9095668" # Amazon Linux 2023
  instance_type               = "c7i-flex.large"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_and_k8s.id]
  associate_public_ip_address = true
  
 

  tags = {
    Name = "Harness-Minikube-Node"
  }
}

output "instance_public_ip" {
  value       = aws_instance.kubernetes_node.public_ip
  description = "The public IP of the instance"
}
