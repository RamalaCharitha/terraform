provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "kubernetes_node" {
  ami           = "ami-08f44e8eca9095668" # Ubuntu 22.04 LTS or 24.04 LTS in us-east-1
  instance_type = "c7i-flex.large"

  # User Data script executed automatically at system startup
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # 1. Update and install basic dependencies
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common

              # 2. Install official Docker Engine
              curl -fsSL https://docker.com | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://docker.com $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io

              # 3. Add the 'ubuntu' user to the docker group
              usermod -aG docker ubuntu
              
              # Restart docker to apply changes cleanly
              systemctl restart docker

              # 4. Install Kubectl CLI
              curl -LO "https://k8s.io(curl -L -s https://k8s.io)/bin/linux/amd64/kubectl"
              install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

              # 5. Install Minikube
              curl -LO https://googleapis.com
              install minikube-linux-amd64 /usr/local/bin/minikube

              # 6. CRITICAL: Start Minikube strictly as the 'ubuntu' user context
              # We use 'sudo -i -u ubuntu' because minikube blocks running directly as root
              sudo -i -u ubuntu minikube start --driver=docker
              EOF

  tags = {
    Name = "Harness-Minikube-Via-UserData"
  }
}

output "instance_public_ip" {
  value       = aws_instance.kubernetes_node.public_ip
  description = "The public IP of the newly created EC2 instance"
}
