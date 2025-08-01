resource "aws_instance" "postgresql" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  # key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              echo "DB_PASSWORD='${var.db_password}'" >> /etc/environment
              EOF

  tags = merge(var.common_tags, {
    Name     = "${var.project_name}-${var.environment}-postgresql-server"
    Type     = "postgresql-server"
    Database = "postgresql"
  })
}