packer {
  required_plugins {
    amazon = {
      version = ">= 1.3"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-west-1"  # ireland
}

variable "ami_source_id" {
  type    = string
  default = "ami-0715d656023fe21b4"  # debian 12 ireland
}

variable "ami_name" {
  type    = string
  default = "debian-apache-{{timestamp}}"
}

source "amazon-ebs" "debian" {
  #access_key   = var.aws_access_key
  #secret_key   = var.aws_secret_key
  region       = var.region
  source_ami   = var.ami_source_id
  instance_type = "t2.micro"
  ssh_username  = "admin"
  ami_name      = var.ami_name
  ami_description = "Debian AMI with Apache HTTP Server"
  ssh_wait_timeout = "10m"
  tags = {
    Name        = var.ami_name
    Purpose = "packer lab"
  }
}

build {
  sources = ["source.amazon-ebs.debian"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apache2",
      "echo '<h1>hello lab one</h1>' | sudo tee /var/www/html/index.html",
      "sudo systemctl enable apache2",
      "sudo systemctl start apache2"
    ]
  }
}
