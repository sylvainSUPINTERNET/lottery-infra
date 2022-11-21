terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.1.4"
}

provider "aws" {
  region = "eu-west-3"
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name             = "Lobbies"
  billing_mode     = "PROVISIONED"
  read_capacity    = 1
  write_capacity   = 1
  hash_key         = "LobbyId"
  range_key        = "LobbyName"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "LobbyId"
    type = "S"
  }

  attribute {
    name = "LobbyName"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }
}




  # resource "aws_iam_role" "iam_for_lambda" {
  #   name = "iam_for_lambda"

  #   assume_role_policy = <<EOF
  # {
  #   "Version": "2012-10-17",
  #   "Statement": [
  #     {
  #       "Action": "sts:AssumeRole",
  #       "Principal": {
  #         "Service": "lambda.amazonaws.com"
  #       },
  #       "Effect": "Allow",
  #       "Sid": ""
  #     }
  #   ]
  # }
  # EOF
  # }

  variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "account_id" {
  type    = string
  default = "018525431968"
} 

variable "table_name" {
  type    = string
  default = "Lobbies"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# https://stackoverflow.com/questions/70016674/invalidparametervalueexception-cannot-access-stream
data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams"
    ]
    resources = [
      aws_dynamodb_table.basic-dynamodb-table.arn
    ]
  }
}

resource "aws_iam_policy" "dynamodb_lambda_policy" {
  name        = "dynamodb-lambda-policy"
  description = "This policy will be used by the lambda to write get data from DynamoDB"
  policy      = data.aws_iam_policy_document.lambda_policy_document.json
}
resource "aws_iam_role_policy_attachment" "lambda_attachements" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.dynamodb_lambda_policy.arn
}


# Archive the code or project that we want to run
# data "archive_file" "lambda_zip" {
#     type          = "zip"
#     source_file   = "app.js"
#     output_path   = "lambda_function.zip"
# }

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_file = "${path.module}/app.js"
#   output_path = "${path.module}/lambda_function.zip"
# }


resource "aws_lambda_function" "my-lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.iam_for_lambda.arn

  # handler       = "index.test"
  handler       = "app.lambdaHandler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("lambda_function.zip")

  runtime = "nodejs16.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}



  resource "aws_lambda_event_source_mapping" "example" {
    event_source_arn  = "${aws_dynamodb_table.basic-dynamodb-table.stream_arn}"
    function_name     = aws_lambda_function.my-lambda.arn
    starting_position = "LATEST"
  }



  # TODO : 
  # 1. Generate lambda from tf ( use zip generated from local lambda with SAM )
  # 2. Generate trigger with this lambda on the table https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
