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

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create a Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a" 
}

# Create a Security Group
resource "aws_security_group" "allow_http" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "hello-world-cluster"
}

# Define the ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                = "hello-world-task"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"

  container_definitions = jsonencode([{
    name      = "hello-world-container"
    image     = var.docker_image
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
      }
    ]
  }])
}

# Create an ECS Service
resource "aws_ecs_service" "app" {
  name            = "hello-world-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.main.id]
    security_groups  = [aws_security_group.allow_http.id]
    assign_public_ip = true
  }
}

# Outputs the service URL to be accesed 
output "service_url" {
  value = "http://${aws_ecs_service.app.id}"
}