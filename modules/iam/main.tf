data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# One role per function so each gets only the permissions it needs.
resource "aws_iam_role" "collector" {
  name               = "collector-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name  = "collector-lambda-role"
    Owner = var.resource_owner["owner"]
  }
}

resource "aws_iam_role" "reader" {
  name               = "reader-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name  = "reader-lambda-role"
    Owner = var.resource_owner["owner"]
  }
}

data "aws_iam_policy_document" "write" {
  statement {
    sid       = "CollectorWrite"
    actions   = ["dynamodb:BatchWriteItem", "dynamodb:PutItem"]
    resources = [var.dynamo_metric_arn]
  }
}

data "aws_iam_policy_document" "read" {
  statement {
    sid       = "ReaderQuery"
    actions   = ["dynamodb:GetItem", "dynamodb:Query"]
    resources = [var.dynamo_metric_arn]
  }
}

resource "aws_iam_policy" "write" {
  name        = "${var.dynamo_table_name}-write"
  description = "Collector Lambda: write items to ${var.dynamo_table_name}"
  policy      = data.aws_iam_policy_document.write.json
}

resource "aws_iam_policy" "read" {
  name        = "${var.dynamo_table_name}-read"
  description = "Reader Lambda: read items from ${var.dynamo_table_name}"
  policy      = data.aws_iam_policy_document.read.json
}

resource "aws_iam_role_policy_attachment" "collector_write" {
  role       = aws_iam_role.collector.name
  policy_arn = aws_iam_policy.write.arn
}

resource "aws_iam_role_policy_attachment" "reader_read" {
  role       = aws_iam_role.reader.name
  policy_arn = aws_iam_policy.read.arn
}
