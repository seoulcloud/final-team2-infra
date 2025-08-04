resource "aws_instance" "mongodb" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  # key_name               = var.key_name

  tags = merge(var.common_tags, {
    Name     = "${var.project_name}-${var.environment}-mongodb-server"
    Type     = "mongodb-server"
    Database = "mongodb"
  })
}
