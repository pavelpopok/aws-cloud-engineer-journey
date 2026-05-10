output "hello_function_name" {
  value = aws_lambda_function.hello.function_name
}

output "hello_function_arn" {
  value = aws_lambda_function.hello.arn
}

output "api_endpoint" {
  value       = aws_apigatewayv2_stage.default.invoke_url
  description = "Base URL — append /hello to call the function"
}
