terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.50" }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  # Correct way to use the endpoints block for LocalStack S3
  endpoints {
    s3 = "http://localhost:4566"
  }


  # This is the crucial line for fixing the DNS issue with S3
  s3_use_path_style = true

   default_tags {
    tags = {
      Environment = "local"
    }
  }

  # path-style now automatically picks up AWS_USE_PATH_STYLE_ENDPOINT=true env var
}

