locals {
  service_port = var.app_port
}

resource "aws_security_group" "alb" {
  name        = "tracknow-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tracknow-alb-sg"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "tracknow-ecs-tasks-sg"
  description = "ECS tasks security group"
  vpc_id      = var.vpc_id

  ingress {
    description      = "App traffic from ALB"
    from_port        = local.service_port
    to_port          = local.service_port
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tracknow-ecs-tasks-sg"
  }
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "tracknow-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "app" {
  name               = "tracknow-app-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets_ids

  tags = {
    Name = "tracknow-app-alb"
  }
}

resource "aws_lb_target_group" "pedidos" {
  name        = "tg-pedidos"
  port        = local.service_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "tg-pedidos"
  }
}

resource "aws_lb_target_group" "rastreamento" {
  name        = "tg-rastreamento"
  port        = local.service_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "tg-rastreamento"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pedidos.arn
  }
}

resource "aws_lb_listener_rule" "rastreamento_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rastreamento.arn
  }

  condition {
    path_pattern {
      values = ["/rastreamento*", "/tracking*"]
    }
  }
}

resource "aws_ecs_task_definition" "pedidos" {
  family                   = "svc-pedidos"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "pedidos"
      image     = var.container_image_pedidos
      essential = true
      portMappings = [{
        containerPort = local.service_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/pedidos"
          awslogs-region        = "sa-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "rastreamento" {
  family                   = "svc-rastreamento"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "rastreamento"
      image     = var.container_image_rastreamento
      essential = true
      portMappings = [{
        containerPort = local.service_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/rastreamento"
          awslogs-region        = "sa-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "pedidos" {
  name            = "svc-pedidos"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.pedidos.arn
  desired_count   = var.desired_count_pedidos
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_app_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pedidos.arn
    container_name   = "pedidos"
    container_port   = local.service_port
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "rastreamento" {
  name            = "svc-rastreamento"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.rastreamento.arn
  desired_count.  = var.desired_count_rastreamento
}
