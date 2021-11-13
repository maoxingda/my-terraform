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

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "dms_source_endpoint_9527"
  username             = "root"
  password             = "123456"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = true
}
