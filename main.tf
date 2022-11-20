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


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping



}