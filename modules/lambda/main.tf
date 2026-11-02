locals {
  tags = {
    Name  = var.function_name
    Owner = var.resource_owner["owner"]
  }
}

data "archive_file" "lambda_function_payload" {
  type        = "zip"
  source_file = "${path.module}/script.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# Created here (not by Lambda itself) so retention is set and the role only
# needs CreateLogStream/PutLogEvents on this one group.
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# Failed asynchronous invocations land here after the retries are used up.
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.function_name}-dlq"
  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true
  tags                      = local.tags
}

data "aws_iam_policy_document" "lambda_ops" {
  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  statement {
    sid       = "SendToDeadLetterQueue"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq.arn]
  }
}

resource "aws_iam_role_policy" "lambda_ops" {
  name   = "logs-and-dlq"
  role   = var.role_name
  policy = data.aws_iam_policy_document.lambda_ops.json
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = var.function_name
  filename         = data.archive_file.lambda_function_payload.output_path
  source_code_hash = data.archive_file.lambda_function_payload.output_base64sha256
  role             = var.role_arn
  handler          = "script.handler"
  runtime          = var.lambda_runtime
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = {
      TABLE_NAME = var.table_name
      TARGETS    = jsonencode(var.targets)
      LOG_LEVEL  = "INFO"
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_ops,
  ]

  tags = local.tags
}

resource "aws_lambda_function_event_invoke_config" "retries" {
  function_name          = aws_lambda_function.lambda_function.function_name
  maximum_retry_attempts = 2
}

# ---------------------------------------------------------------------------
# Schedule: EventBridge invokes the function every interval
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.function_name}-schedule"
  schedule_expression = var.schedule_expression
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_lambda_function.lambda_function.arn
}

resource "aws_lambda_permission" "events" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "${var.function_name}-errors"
  alarm_description   = "The collector Lambda reported an error"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = aws_lambda_function.lambda_function.function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  tags                = local.tags
}
