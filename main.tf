terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

variable "access_key" {
  description = "AWS Access Key ID"
}

variable "secret_key" {
  description = "AWS Secret Access Key"
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "eu-north-1"
}

# Security Group definition
resource "aws_security_group" "launch_wizard_sg" {
  name        = "launch-wizard-2"
  description = "launch-wizard-2 created 2024-05-01T18:19:45.244Z"
  vpc_id      = "vpc-0c4bcc31755a8df93"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["213.149.169.233/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "example_instance" {
  ami                        = "ami-03035978b5aeb1274"
  instance_type              = "t3.micro"
  key_name                   = "pair-key"
  ebs_optimized              = true
  associate_public_ip_address = true
  security_groups            = [aws_security_group.launch_wizard_sg.name]

  root_block_device {
    volume_size           = 10
    delete_on_termination = true
    encrypted             = false
  }
}

# Initial EBS Volume for Snapshot
resource "aws_ebs_volume" "initial_ebs_volume" {
  availability_zone = aws_instance.example_instance.availability_zone
  size              = 10
  type              = "gp3"
  iops              = 3000
  throughput        = 125

  tags = {
    Name = "Initial EBS Volume"
  }
}

resource "aws_volume_attachment" "initial_volume_attachment" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.initial_ebs_volume.id
  instance_id  = aws_instance.example_instance.id
}

# Snapshot of the Initial EBS Volume
resource "aws_ebs_snapshot" "initial_ebs_snapshot" {
  volume_id = aws_ebs_volume.initial_ebs_volume.id

  tags = {
    Name = "Snapshot of Initial EBS Volume"
  }
}

# EBS Volume from created snapshot
resource "aws_ebs_volume" "example_ebs_volume" {
  availability_zone = aws_instance.example_instance.availability_zone
  snapshot_id       = aws_ebs_snapshot.initial_ebs_snapshot.id
  type              = "gp3"
  size              = 10
  iops              = 3000
  throughput        = 125

  tags = {
    Name = "EBS Volume from Snapshot"
  }
}

resource "aws_volume_attachment" "ebs_attachment" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.example_ebs_volume.id
  instance_id  = aws_instance.example_instance.id
}
