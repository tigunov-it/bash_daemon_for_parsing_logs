//get latest ubuntu 22.04 ARM
data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }
}

resource "aws_instance" "parse_log" {
  ami = data.aws_ami.latest_ubuntu.id
  instance_type = "t4g.small"
  vpc_security_group_ids = [aws_security_group.allow_ssh_from_my_ip.id]
  key_name = var.aws_key_name
  tags = {
    "Name" = "parse_log"
  }
  root_block_device {
    volume_size = 10
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = file(var.path_to_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname stage",
    ]
  }
}

resource "aws_security_group" "allow_ssh_from_my_ip" {
  name        = "allow_ssh_from_my_ip"
  description = "Allow ssh from from my ips"

  dynamic "ingress" {
    for_each = var.allow_ingress_ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = [var.client_ip_address[0], var.client_ip_address[1]]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_from_my_ips"
  }
}

resource "local_file" "inventory" {
  content = templatefile("./templates/inventory.tfpl", {
    host_name = aws_instance.parse_log.public_ip
  })
  filename   = ".././ansible/hosts_aws.yaml"
  depends_on = [aws_instance.parse_log]
}

resource "local_file" "unit_name_vars" {
  content = templatefile("./templates/unit_name_vars.tfpl", {
    service = var.service
    logpath = var.logpath
    logfile = var.logfile
    badstring = var.badstring
  })
  filename   = ".././ansible/roles/parselog/vars/main.yml"
}
