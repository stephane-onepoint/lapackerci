provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "my_webserver" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  security_groups = ["allow_http"]

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
