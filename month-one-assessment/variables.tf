variable "region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type_web" {
  description = "Instance type for Web Servers"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_db" {
  description = "Instance type for Database Server"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the SSH key pair to access instances"
  type        = string
}

variable "my_ip" {
  description = "Your current public IP address for SSH access (use CIDR notation, e.g., 1.2.3.4/32)"
  type        = string
}