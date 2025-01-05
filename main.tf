provider "aws" {
  region = "eu-west-1"
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from anywhere
  }
}

resource "aws_instance" "my_webserver" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.allow_http.name]

  tags = {
    Name = "my http server"
  }

  associate_public_ip_address = true
}

output "instance_id" {
  value = aws_instance.my_webserver.id
}

output "public_ip" {
  value = aws_instance.my_webserver.public_ip
}

variable "ami_id" {
  type = string
}
