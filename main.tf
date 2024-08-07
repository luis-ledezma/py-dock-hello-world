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

# ----------------
# LOAD BALANCER
# ----------------

resource "aws_lb" "lb" {
  name            = "py-docker-hello-world-lb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "lb_target_group" {
  name        = "py-docker-hello-world-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.lb_target_group.id
    type             = "forward"
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
    name      = "py-docker-hello-world-container"
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
    subnets          = aws_subnet.private.*.id
    security_groups  = [aws_security_group.allow_http.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.id
    container_name   = "py-docker-hello-world-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.lb_listener]
}