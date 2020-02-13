##################################################################################
# VARIABLES
##################################################################################

variable "region" {
  default = "us-east-1"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  region     = var.region
}

##################################################################################
# DATA
##################################################################################

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


##################################################################################
# RESOURCES
##################################################################################

resource "aws_key_pair" "terra-keypair" {
key_name = "terra-keypair"
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbz6ghXnM3JgyKanclkEcZ/h9OPybi7voPsUTIvFm6Uh0HkdN8eKiuOZ8XY/rMruCouHpSNo3wUNkQMU4aUD7xHX25HnLIhg1QRQsTWnHz8QZaX2z4a1sapL7O0zGajFI3UpG1IYUxZOwmVWWjVF3tye68lfn/KxQm42wFmzJrbrImQ+dJjrxz0BzNzSGovM3pl8pD6hB96tZbE5MTkQljvVR5rm/xIpGnVXPdRA0knkyPVwYb5A/vDkk9CmfqG3iYdOI8IKId8aUDn+q/aNkQ6dxoDw6250Rql1u13FEe7MdCc9N8WLjI+UvcJ6U9/7b9UHhI84upv/gpyNWFhE8b ec2-user@ip-172-31-80-206"
}

#This uses the default VPC.  It WILL NOT delete it on destroy.
resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "allow-ssh" {
  name        = "nginx_demo"
  description = "Allow ports for nginx demo"
  vpc_id      = aws_default_vpc.default.id

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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  #key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]

  user_data = <<-EOF
		    #! /bin/bash
                    sudo yum install nginx -y
                    sudo service nginx start
                    echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
                 EOF

   connection {
    type        = "ssh"
    host        = self.public_ip
    agent       = false
    user        = "ec2-user"

             }
    }


##################################################################################
# OUTPUT
##################################################################################

output "aws_instance_public_dns" {
  value = aws_instance.nginx.public_dns
}
