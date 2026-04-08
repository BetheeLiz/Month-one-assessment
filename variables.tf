variable "region" {
  description = "The AWS region to deploy in"
  default     = "us-east-1"
}

variable "instance_type_web" {
  description = "Instance type for web servers"
  default     = "t3.micro"
}

variable "instance_type_db" {
  description = "Instance type for the database server"
  default     = "t3.small"
}

variable "key_name" {
  description = "The name of the key pair"
  default     = "Bethee-aws-key"
}

variable "my_ip" {
  description = "Your current public IP for SSH access (e.g., 1.2.3.4/32)"
  default     = "0.0.0.0/0" 
}