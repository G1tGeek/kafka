output "bastion_public_ip" {
  value = aws_instance.public.public_ip
  description = "The public IP address of the bastion host."
}

# Output for Application Host Private IP
output "application_private_ip" {
  value = aws_instance.private1.private_ip
  description = "The private IP address of the application host."
}

# Output for Kafka Host Private IP
output "kafka_private_ip" {
  value = aws_instance.private2.private_ip
  description = "The private IP address of the Kafka host."
}

# Output for Database Host Private IP
output "database_private_ip" {
  value = aws_instance.private3.private_ip
  description = "The private IP address of the database host."
}
