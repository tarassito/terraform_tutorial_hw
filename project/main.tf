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

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "developer_role" {
  name               = "developer_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_iam_policy" "developer_policy" {
  name = "developer_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "kinesis:*",
          "s3:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.developer_policy.arn
  role       = aws_iam_role.developer_role.name
}


data "archive_file" "http_to_kinesis_code" {
  type        = "zip"
  source_file = "lambdas/HTTPToKinesis.py"
  output_path = "lambdas/http_to_kinesis.zip"
}

resource "aws_lambda_function" "http_to_kinesis_auto" {
  filename      = "lambdas/http_to_kinesis.zip"
  function_name = "HTTPToKinesisAuto"
  role          = aws_iam_role.developer_role.arn
  handler       = "HTTPToKinesis.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      DATA_STREAM_NAME = var.stream_name
    }
  }
}

resource "aws_lambda_function_url" "lambda_url" {
  function_name      = aws_lambda_function.http_to_kinesis_auto.function_name
  authorization_type = "AWS_IAM"
}

data "archive_file" "kinesis_to_s3_code" {
  type        = "zip"
  source_file = "lambdas/KinesisToS3Auto.py"
  output_path = "lambdas/kinesis_to_s3.zip"
}

resource "aws_lambda_function" "kinesis_to_s3_auto" {
  filename      = "lambdas/kinesis_to_s3.zip"
  function_name = "KinesisToS3Auto"
  role          = aws_iam_role.developer_role.arn
  handler       = "KinesisToS3.lambda_handler"
  runtime       = "python3.9"

}

resource "aws_kinesis_stream" "stream_auto" {
  name             = var.stream_name
  shard_count      = 1
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

}