output "jenkins_public_DNS" {
  value = "ssh ubuntu@${aws_instance.ubuntu_with_docker.public_dns}"
}

output "application_instance" {
    value = aws_instance.main.public_ip
}