output "ec2_public_ip" {
    description = "Public IP of EC2"
    value = aws_instance.web_server.public_ip
}
