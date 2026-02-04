resource "aws_db_subnet_group" "this" {
  name       = "tracknow-rds-subnets"
  subnet_ids = var.private_data_subnets

  tags = {
    Name = "tracknow-rds-subnets"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "tracknow-rds-sg"
  description = "Security group for TrackNow RDS"
  vpc_id      = var.vpc_id

  # Ajusta o CIDR para o da sua VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tracknow-rds-sg"
  }
}

resource "aws_db_instance" "this" {
  identifier = "tracknow-rds"

  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "14.1"
  instance_class       = "db.t3.micro"

  db_name  = var.db_name
  username = var.master_username
  password = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0

  tags = {
    Name = "tracknow-rds"
  }
}
