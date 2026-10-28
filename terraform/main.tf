provider "aws" {
  region = "ap-south-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "vle8" {
  key_name   = "vle8-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "vle8" {
  name = "vle8-sg"
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

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.vle8.key_name
  vpc_security_group_ids = [aws_security_group.vle8.id]
  tags = {
    Name = "VLE8-Terraform-Jenkins"
  }
}

output "public_ip" {
  value = aws_instance.jenkins.public_ip
}
