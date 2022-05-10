provider "aws" {
  region  = "eu-central-1"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "uaworks-bot-bucket"

#   acl           = "private"
  force_destroy = true
}

data "archive_file" "lambda_uaworks" {
  type = "zip"

  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/uaworks.zip"
}

resource "aws_s3_object" "lambda_uaworks" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "uaworks.zip"
  source = data.archive_file.lambda_uaworks.output_path

  etag = filemd5(data.archive_file.lambda_uaworks.output_path)
}

resource "aws_lambda_function" "uaworks" {
  function_name = "UAWorks"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_uaworks.key

  runtime = "nodejs14.x"
  handler = "index.publishJobs"

  source_code_hash = data.archive_file.lambda_uaworks.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "uaworks" {
  name = "/aws/lambda/${aws_lambda_function.uaworks.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "uaworks_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_event_rule" "console" {
  name        = "uaworks-bot-publish-new-jobs"
  description = "Telegram bot publishes new jobs"
  schedule_expression = "0 8-20 * * *"
}

resource "aws_cloudwatch_event_target" "uaworks_targer" {
  rule      = aws_cloudwatch_event_rule.console.name
  target_id = "BotPublishJobs"
  arn       = aws_lambda_function.uaworks.arn
}

# resource "aws_lambda_permission" "api_gw" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.uaworks.function_name
#   principal     = "apigateway.amazonaws.com"

#   source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
# }


