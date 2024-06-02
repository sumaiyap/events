data "aws_ami" "ubuntu_22_04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] 
}


resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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

# Import the public key
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Launch an EC2 instance with Docker preinstalled
resource "aws_instance" "ubuntu_with_docker" {
  ami           = data.aws_ami.ubuntu_22_04.id
  instance_type = var.jenkins_instance # Change this to your preferred instance type
  key_name      = aws_key_pair.my_key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.ecr_access_instance_profile.name

  security_groups = [aws_security_group.allow_ssh.name]
  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update -y
              apt-get install -y docker-ce
              usermod -aG docker ubuntu
              systemctl enable docker
              systemctl start docker
              sudo apt-get update -y
              sudo apt install openjdk-11-jdk -y
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt update -y
              sudo apt install jenkins -y
              sudo apt-get install -y awscli
              EOF

  tags = {
    Name = "Jenkins"
  }
}


resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu_22_04.id
  instance_type = var.jenkins_instance # Change this to your preferred instance type
  key_name      = aws_key_pair.my_key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.ecr_access_instance_profile.name

  security_groups = [aws_security_group.allow_ssh.name]
  root_block_device {
    volume_size = 100
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update -y
              apt-get install -y docker-ce
              usermod -aG docker ubuntu
              systemctl enable docker
              systemctl start docker
              curl -L "https://github.com/docker/compose/releases/download/v2.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              sudo apt-get install -y awscli
              EOF

  tags = {
    Name = "Docker"
  }
}