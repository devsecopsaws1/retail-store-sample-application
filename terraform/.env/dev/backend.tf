bucket = "terraform-state-dev-retail-store"
key    = "dev/terraform.state"
region = "us-east-1"
encrypt = true
dynamodb_table = "terraform-state-lock-dev"