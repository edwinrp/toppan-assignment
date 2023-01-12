terraform {
  required_providers{
    aws = {
        source = "hashicorp/aws"
        version = "~>4.3.0"
    }
  }
}

provider "aws" {
    profile = "default"
    region = "ap-southeast-1"
  
}


# Creating VPC,name, CIDR and Tags
resource "aws_vpc" "toppan-assignment-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "toppan_assignment_vpc"
  }
}
# Creating Public Subnets in VPC
resource "aws_subnet" "toppan-public-subnet" {
  vpc_id                  = aws_vpc.toppan-assignment-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-southeast-1a"
  tags = {
    Name = "toppan-public-subnet"
  }
}

# Creating Public Subnets 2 in VPC
resource "aws_subnet" "toppan-public-subnet-2" {
  vpc_id                  = aws_vpc.toppan-assignment-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-southeast-1b"
  tags = {
    Name = "toppan-public-subnet-2"
  }
}

# Creating Private Subnets in VPC
resource "aws_subnet" "toppan-private-subnet" {
  vpc_id                  = aws_vpc.toppan-assignment-vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-southeast-1a"
  tags = {
    Name = "toppan-private-subnet"
  }
}

# Creating Internet Gateway in AWS VPC
resource "aws_internet_gateway" "toppan-igw" {
  vpc_id = aws_vpc.toppan-assignment-vpc.id
  tags = {
    Name = "toppan-igw"
  }
}
# Creating Route Tables for Internet gateway
resource "aws_route_table" "toppan-public-route-table" {
  vpc_id = aws_vpc.toppan-assignment-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.toppan-igw.id
  }
  tags = {
    Name = "toppan-route-table-public-igw"
  }
}
# Creating Route Associations public subnets
resource "aws_route_table_association" "toppan_assignment_vpc_public_route_association" {
  subnet_id      = aws_subnet.toppan-public-subnet.id
  route_table_id = aws_route_table.toppan-public-route-table.id
}

# Creating Route Associations public subnets - 2
resource "aws_route_table_association" "toppan_assignment_vpc_public_route_association-2" {
  subnet_id      = aws_subnet.toppan-public-subnet-2.id
  route_table_id = aws_route_table.toppan-public-route-table.id
}

# Creating Nat Gateway
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.toppan-public-subnet.id
  depends_on    = [aws_internet_gateway.toppan-igw]
}

# Add routes for VPC
resource "aws_route_table" "toppan-private-route-table" {
  vpc_id = aws_vpc.toppan-assignment-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "toppan-route-table-private-natgw"
  }
}

# Creating route associations for private Subnets
resource "aws_route_table_association" "toppan_assignment_vpc_private_route_association" {
  subnet_id      = aws_subnet.toppan-private-subnet.id
  route_table_id = aws_route_table.toppan-private-route-table.id
}

# Creating Security Group for ELB
resource "aws_security_group" "toppan_elb_sg" {
  name        = "toppan_elb_sg"
  description = "allow 80"
  vpc_id      = aws_vpc.toppan-assignment-vpc.id

# Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating Security Group for ELB EC2
resource "aws_security_group" "toppan_elb_sg_ec2" {
  name        = "toppan_elb_sg_ec2"
  description = "allow 80"
  vpc_id      = aws_vpc.toppan-assignment-vpc.id

# Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ASG Launch Template

resource "aws_launch_template" "toppan_launch_template" {
  name = "toppan_launch_template"
  instance_type = "t2.micro"
  image_id = "ami-005835d578c62050d"

  user_data = file("data.sh")

    network_interfaces {
      subnet_id = "subnet-03ca9ed8479591e24"
      security_groups = [aws_security_group.toppan_elb_sg_ec2.id]


  }

  iam_instance_profile {
    name = "ec2CallS3"
  }

}



# Auto Scaling group
resource "aws_autoscaling_group" "toppan_asg" {
    #launch_configuration = aws_launch_configuration.toppan_asg_launch_configuration.name
    name = "toppan_asg"
    
    launch_template {
      id = aws_launch_template.toppan_launch_template.id
      version = "$Latest"
    }
    
    vpc_zone_identifier = [aws_subnet.toppan-private-subnet.id]
    

    target_group_arns = [aws_lb_target_group.toppan_asg.arn]
    health_check_type = "ELB"

    # Minimum and maximum size of Auto Scaling Group
    min_size = 3
    max_size = 3

    # Name the ASG 
    tag {
        key = "Name"
        value = "Toppan ASG"
        propagate_at_launch = true
    }
}

# Application Load Balancer
resource "aws_lb" "toppan_alb" {
    name = "toppanalb"
    load_balancer_type = "application"
    subnets = [aws_subnet.toppan-public-subnet.id, aws_subnet.toppan-public-subnet-2.id]
    security_groups = [aws_security_group.toppan_elb_sg.id]
}

# Listening port for Application Load Balancer
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.toppan_alb.arn
    port = 80
    protocol = "HTTP"

    # Default return 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

# Listener rule for Application Load Balancer
resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
      path_pattern {
          values = ["*"]
      }
    }

    # Distribute requests to 1 or more target groups
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.toppan_asg.arn
    }
}

# Target group 1 for Application Load Balancer
resource "aws_lb_target_group" "toppan_asg" {
    name = var.toppan_tg

    port = var.server_port
    protocol = "HTTP"
    vpc_id = aws_vpc.toppan-assignment-vpc.id

    health_check {
      path = "/"
      protocol = "HTTP"
      matcher = "200"
      interval = 15
      timeout = 3

      # Number of consecutive health checks before consider target as unhealthy
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
}