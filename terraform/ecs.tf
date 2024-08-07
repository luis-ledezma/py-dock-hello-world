# Create an ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "py-docker-hello-world-cluster"
}

# Define the ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "py-docker-hello-world-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::025066248951:role/ecsTaskExecutionRole"

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