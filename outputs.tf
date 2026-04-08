output "vpc_id" {
  description = "The ID of the TechCorp VPC"
  value       = aws_vpc.techcorp_vpc.id
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

output "bastion_public_ip" {
  description = "The Public IP of the Bastion Host"
  value       = aws_instance.bastion.public_ip
}