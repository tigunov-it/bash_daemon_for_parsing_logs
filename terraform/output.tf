output "instance_public_ip" {
  value = aws_instance.parse_log.public_ip
}
