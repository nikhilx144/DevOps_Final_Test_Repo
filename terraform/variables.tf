variable "region" {
    description = "AWS Region"
    type = string
}

variable "instance_type" {
    description = "EC2 Instance Type"
    type = string
}

variable "ami_id" {
    description = "EC2 Instance AMI ID"
    type = string
}

variable "key_name" {
    description = "AWS Key Pair"
    type = string
}