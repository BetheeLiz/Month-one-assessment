provider "aws" {
  region = var.region
}

# 1. VPC & Networking
resource "aws_vpc" "techcorp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "techcorp-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.techcorp_vpc.id
  tags   = { Name = "techcorp-igw" }
}

# Subnets in Two AZs
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  tags = { Name = "techcorp-public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = true
  tags = { Name = "techcorp-public-subnet-2" }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"
  tags = { Name = "techcorp-private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"
  tags = { Name = "techcorp-private-subnet-2" }
}

# NAT Gateway for Private Subnets
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "techcorp-nat" }
}

# Routing
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "priv1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "priv2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

# 2. Security Groups
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.techcorp_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.techcorp_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.techcorp_vpc.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Keys and Instances
resource "aws_key_pair" "tech_key" {
  key_name   = var.key_name
  public_key = file("${var.key_name}.pub")
}

resource "aws_instance" "bastion" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_1.id
  key_name      = aws_key_pair.tech_key.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  tags = { Name = "techcorp-bastion" }
}

resource "aws_instance" "web_servers" {
  count         = 2
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = var.instance_type_web
  subnet_id     = count.index == 0 ? aws_subnet.private_1.id : aws_subnet.private_2.id
  key_name      = aws_key_pair.tech_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data     = file("user_data/web_server_setup.sh")
  tags          = { Name = "techcorp-web-server-${count.index + 1}" }
}

resource "aws_instance" "db_server" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = var.instance_type_db
  subnet_id     = aws_subnet.private_1.id
  key_name      = aws_key_pair.tech_key.key_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  user_data     = file("user_data/db_server_setup.sh")
  tags          = { Name = "techcorp-db-server" }
}

# 4. Load Balancer
resource "aws_lb" "web_alb" {
  name               = "techcorp-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp_vpc.id
  health_check { path = "/" }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "web_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_servers[count.index].id
  port             = 80
}