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

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
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
  user_data = file("./jenkins_data/user_data.sh")

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
  user_data = file("./app_data/user_data.sh")

  tags = {
    Name = "web-app"
  }
}