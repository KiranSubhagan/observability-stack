terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Recommended: use a remote backend for state storage/locking.
  # Configure via `terraform init -backend-config=backend.hcl`
  # or uncomment and fill in directly.
  #
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "recovery-event-forwarder/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}
