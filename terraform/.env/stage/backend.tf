bucket = "terraform-state-stage-retail-store"
key    = "stage/terraform.state"
region = "us-east-1"
encrypt = true
dynamodb_table = "terraform-state-lock-stage"