terraform {
  required_version = "~>1.1.7"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  function_name = "release_monitorTF"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  zip_file      = "release_monitorTF.zip"
  account       = "seisoLLC"
  repository    = "easy_infra"
  commit        = "8edca625e966f41020dee1b6a913be6f71f41476"
}

data "archive_file" "zip" {
  excludes = [
    ".env",
    ".terraform",
    ".terraform.lock.hcl",
    "docker-compose.yml",
    "terraform/*",
    # "terraform/main.tf",
    # "terraform/terraform.tfstate",
    # "terraform/terraform.tfstate.backup",
    "local.zip_file",
  ]
  source_dir = path.module
  type       = "zip"

  output_path = "${path.module}/${local.zip_file}"
}

data "aws_iam_policy_document" "lambdaPlusCWlogs" {

  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "release_monitorTFrole" {
  assume_role_policy = data.aws_iam_policy_document.lambdaPlusCWlogs.json
}

resource "aws_iam_role_policy_attachment" "release_monitorTFattach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.release_monitorTFrole.name
}

resource "aws_lambda_function" "release_monitorTFlambda" {
  function_name    = local.function_name
  handler          = local.handler
  runtime          = local.runtime
  filename         = local.zip_file
  source_code_hash = data.archive_file.zip.output_base64sha256
  role             = aws_iam_role.release_monitorTFrole.arn
}

# data "aws_lambda_invocation" "release_monitorInvoke" {
#     function_name = aws_lambda_function.release_monitorTFlambda.function_name
#     input = <<JSON
# {
#   "account": "seisollc",
#   "commit": "8edca625e966f41020dee1b6a913be6f71f41476",
#   "repository": "easy_infra"
# }
# JSON
# }

resource "aws_cloudwatch_event_rule" "CW_rule" {
  name                = "DailyCronTF"
  description         = "CloudWatch EventBridge cron timer to trigger at midnight ET"
  schedule_expression = "cron(0 4 * * ? *)"
}

resource "aws_cloudwatch_event_target" "CW_target" {
  arn  = aws_lambda_function.release_monitorTFlambda.arn
  rule = aws_cloudwatch_event_rule.CW_rule.id
}