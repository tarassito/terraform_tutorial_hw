output "lambda_function_url" {
  description = "The URL of the Lambda Function URL"
  value       = try(aws_lambda_function_url.lambda_url.function_url, "")
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}

output "db_user" {
  value = random_string.db_user.result
}

output "db_adress" {
  value = aws_db_instance.postgres-db.address
}