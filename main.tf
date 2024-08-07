variable "docker_image" {
    type        = string
    description = "Docker image URI."
}

variable "aws_region" {
    type        = string
    description = "AWS Region for the architecture to be build."
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "py-docker-hello-world-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Create a Subnet
resource "aws_subnet" "public" {
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
  availability_zone       = "us-east-2a"
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)
  availability_zone = "us-east-2b"
  vpc_id            = aws_vpc.main.id
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_eip" "gateway" {
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "gateway" {
  subnet_id     = aws_subnet.public.id
  allocation_id = aws_eip.gateway.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gateway.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create a Security Group
resource "aws_security_group" "allow_http" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "py-docker-hello-world-cluster"
}

# Define the ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                = "py-docker-hello-world-task"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = "arn:aws:iam::025066248951:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([{
    name      = "hello-world-container"
    image     = var.docker_image
    essential = true
    portMappings = [
      {
        containerPort = 8080
        hostPort      = 8080
      }
    ]
  }])
}

# Create an ECS Service
resource "aws_ecs_service" "app" {
  name            = "py-docker-hello-world-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.allow_http.id]
    assign_public_ip = true
  }
}

# Outputs the service URL to be accesed 
output "service_url" {
  value = "http://${aws_ecs_service.app.id}"
}