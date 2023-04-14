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
  filename      = "lambdas/http_to_kinesis.zip"
  function_name = "http_to_kinesis"
  role          = aws_iam_role.developer_role.arn
  handler       = "http_to_kinesis.lambda_handler"
  runtime       = "python3.9"

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
  filename      = "lambdas/kinesis_to_s3.zip"
  function_name = "kinesis_to_s3"
  role          = aws_iam_role.developer_role.arn
  handler       = "kinesis_to_s3.lambda_handler"
  runtime       = "python3.9"

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
  event_source_arn = aws_kinesis_stream.stream_auto.arn
  function_name = aws_lambda_function.kinesis_to_s3.arn
  starting_position = "LATEST"

  depends_on = [
    aws_iam_role_policy_attachment.developer_policy_attachment
  ]

}
