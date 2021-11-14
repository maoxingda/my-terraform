terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "cn-northwest-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0fb395ea2def917dd"
  instance_type = "t2.micro"

  tags = {
    Name = var.instance_name
  }
}

resource "aws_db_instance" "db001" {
  identifier           = "db001"
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = local.database
  username             = local.username
  password             = local.password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = true
  #  db_subnet_group_name = "fan-sandbox"
}

# Create a source endpoint
resource "aws_dms_endpoint" "source001" {
  database_name               = local.database
  endpoint_id                 = "source001"
  endpoint_type               = "source"
  engine_name                 = "mysql"
  extra_connection_attributes = ""
  username                    = local.username
  password                    = local.password
  port                        = 3306
  server_name                 = aws_db_instance.db001.endpoint
  ssl_mode                    = "none"
}

# Create a target endpoint
resource "aws_dms_endpoint" "target001" {
  database_name               = local.database
  endpoint_id                 = "target001"
  endpoint_type               = "target"
  engine_name                 = "mysql"
  extra_connection_attributes = ""
  username                    = local.username
  password                    = local.password
  port                        = 3306
  server_name                 = aws_db_instance.db001.endpoint
  ssl_mode                    = "none"
}

# Create a new replication task
resource "aws_dms_replication_task" "replica-task001" {
  migration_type           = "full-load"
  replication_task_id      = "replica-task001"
  replication_instance_arn = "arn:aws-cn:dms:cn-northwest-1:651844176281:rep:S36HT7VGJ62Y6XOU2OSVW3HBRDQUNGQHT7TVL2Y"

  source_endpoint_arn = aws_dms_endpoint.source001.endpoint_arn
  target_endpoint_arn = aws_dms_endpoint.target001.endpoint_arn

  table_mappings = jsonencode({
    "rules" : [
      {
        "rule-type" : "selection",
        "rule-id" : "1",
        "rule-name" : "1",
        "object-locator" : {
          "schema-name" : local.database,
          "table-name" : "%"
        },
        "rule-action" : "include"
      },
      {
        "rule-type" : "transformation",
        "rule-id" : "2",
        "rule-name" : "2",
        "rule-action" : "add-prefix",
        "rule-target" : "table",
        "object-locator" : {
          "schema-name" : local.database,
          "table-name" : "%"
        },
        "value" : "DMS_"
      }
    ]
  })
}
