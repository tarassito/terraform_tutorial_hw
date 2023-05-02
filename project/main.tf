terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

data "archive_file" "http_to_kinesis_code" {
  type        = "zip"
  source_file = "lambdas/http_to_kinesis.py"
  output_path = "lambdas/http_to_kinesis.zip"
}

resource "aws_lambda_function" "http_to_kinesis" {
  filename         = "lambdas/http_to_kinesis.zip"
  function_name    = "http_to_kinesis"
  role             = aws_iam_role.developer_role.arn
  handler          = "http_to_kinesis.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.http_to_kinesis_code.output_base64sha256

  environment {
    variables = {
      DATA_STREAM_NAME = var.stream_name
    }
  }
}

resource "aws_lambda_function_url" "lambda_url" {
  function_name      = aws_lambda_function.http_to_kinesis.function_name
  authorization_type = "AWS_IAM"
}

data "archive_file" "kinesis_to_s3_code" {
  type        = "zip"
  source_file = "lambdas/kinesis_to_s3.py"
  output_path = "lambdas/kinesis_to_s3.zip"
}

resource "aws_lambda_function" "kinesis_to_s3" {
  filename         = "lambdas/kinesis_to_s3.zip"
  function_name    = "kinesis_to_s3"
  role             = aws_iam_role.developer_role.arn
  handler          = "kinesis_to_s3.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.kinesis_to_s3_code.output_base64sha256

  environment {
    variables = {
      S3_BUCKET = var.bucket_name
    }
  }

}

resource "aws_kinesis_stream" "stream_auto" {
  name             = var.stream_name
  shard_count      = 1
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

}

resource "aws_lambda_function_event_invoke_config" "kinesis_to_s3_trigger" {
  function_name                = aws_lambda_function.kinesis_to_s3.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
}


resource "aws_lambda_event_source_mapping" "kinesis_to_s3_mapping" {
  event_source_arn  = aws_kinesis_stream.stream_auto.arn
  function_name     = aws_lambda_function.kinesis_to_s3.arn
  starting_position = "LATEST"

  depends_on = [
    aws_iam_role_policy_attachment.developer_policy_attachment
  ]

}

resource "random_password" "db_password" {
  length           = 8
  special          = true
  override_special = "<>;()&#!^"
}

resource "random_string" "db_user" {
  length  = 8
  numeric = false
  special = false
  upper   = false
}

resource "aws_db_instance" "postgres-db" {
  identifier             = "clouds-ucu-db"
  instance_class         = "db.t3.micro"
  apply_immediately      = true
  allocated_storage      = 10
  db_name                = "postgres_db"
  username               = random_string.db_user.result
  password               = random_password.db_password.result
  engine                 = "postgres"
  skip_final_snapshot    = true
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.ucu-subnet-group.name
  vpc_security_group_ids = [aws_security_group.ucu-security-group.id]

  depends_on = [aws_vpc.ucu-vpc, aws_db_subnet_group.ucu-subnet-group, aws_security_group.ucu-security-group]
}

data "archive_file" "kinesis_to_db_code" {
  type        = "zip"
  source_file = "lambdas/kinesis_to_db.py"
  output_path = "lambdas/kinesis_to_db.zip"
}

resource "aws_lambda_function" "kinesis_to_db" {
  filename         = "lambdas/kinesis_to_db.zip"
  function_name    = "kinesis_to_db"
  role             = aws_iam_role.developer_role.arn
  handler          = "kinesis_to_db.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.kinesis_to_db_code.output_base64sha256

  environment {
    variables = {
      DB_HOST     = aws_db_instance.postgres-db.address
      DB_PORT     = aws_db_instance.postgres-db.port
      DB_NAME     = aws_db_instance.postgres-db.db_name
      DB_USER     = aws_db_instance.postgres-db.username
      DB_PASSWORD = aws_db_instance.postgres-db.password

    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.ucu-subnet-1.id, aws_subnet.ucu-subnet-2.id]
    security_group_ids = [aws_security_group.ucu-security-group.id]
  }

  layers     = [aws_lambda_layer_version.psycopg2_layer.arn]
  depends_on = [aws_lambda_layer_version.psycopg2_layer, aws_db_instance.postgres-db]

}

resource "aws_lambda_layer_version" "psycopg2_layer" {
  layer_name = "psycopg2_layer"
  filename   = "lambdas/layers/psycopg2.zip"
}

resource "aws_lambda_function_event_invoke_config" "kinesis_to_db_trigger" {
  function_name                = aws_lambda_function.kinesis_to_db.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
}

resource "aws_lambda_event_source_mapping" "kinesis_to_db_mapping" {
  event_source_arn  = aws_kinesis_stream.stream_auto.arn
  function_name     = aws_lambda_function.kinesis_to_db.arn
  starting_position = "LATEST"

  depends_on = [
    aws_iam_role_policy_attachment.developer_policy_attachment
  ]
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
}