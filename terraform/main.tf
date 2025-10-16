resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For learning purposes only. Restrict this to your IP in production!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

resource "aws_key_pair" "deployer_key" {
    key_name   = "test-ec2"
    public_key = file("${path.module}/id_rsa.pub")
}

resource "aws_instance" "web_server" {
  ami = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Attach the key pair and security group
  key_name = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # This script runs on instance start-up to install Docker
  user_data = <<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -a -G docker ec2-user
              EOF

  tags = {
    Name = "WebAppServerDevOpsFinalPrac"
  }
}

# IAM Role that allows the EC2 service to assume it
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attaches the AWS-managed policy for ECR read-only access to the role
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Creates an instance profile to attach the role to an EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ecr-access-profile"
  role = aws_iam_role.ec2_role.name
}