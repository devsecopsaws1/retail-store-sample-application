# Simple Multi-Account Terraform Setup

This is the minimal setup needed for multi-account Terraform with assume role. No shell scripts or bootstrap folders required!

## What You Need

### 1. AWS Resources (Manual Setup)

#### In Each Target Account (Dev/Stage):

**Create IAM Role: `TerraformExecutionRole`**

Trust Policy:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::MANAGEMENT-ACCOUNT:user/github-actions"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

Permissions: Attach `AdministratorAccess` or create custom policy with EKS, EC2, IAM, S3, DynamoDB permissions.

**Create S3 Bucket for State:**
- Dev: `terraform-state-dev-retail-store`
- Stage: `terraform-state-stage-retail-store`

**Create DynamoDB Table for Locking:**
- Dev: `terraform-state-lock-dev`
- Stage: `terraform-state-lock-stage`

#### In Management Account:

**Create IAM User: `github-actions`**

Policy:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": [
                "arn:aws:iam::DEV-ACCOUNT-ID:role/TerraformExecutionRole",
                "arn:aws:iam::STAGE-ACCOUNT-ID:role/TerraformExecutionRole"
            ]
        }
    ]
}
```

### 2. GitHub Configuration

**Secrets:**
- `AWS_ACCESS_KEY_ID`: Management account access key
- `AWS_SECRET_ACCESS_KEY`: Management account secret key

**Variables:**
- `AWS_REGION`: `us-east-1`

### 3. Terraform Configuration

**Update `.env/dev/vars.tfvars`:**
```hcl
assume_role_arn = "arn:aws:iam::DEV-ACCOUNT-ID:role/TerraformExecutionRole"
```

**Update `.env/stage/vars.tfvars`:**
```hcl
assume_role_arn = "arn:aws:iam::STAGE-ACCOUNT-ID:role/TerraformExecutionRole"
```

## That's It!

No bootstrap folders, no shell scripts, no complex OIDC setup. Just:

1. ✅ Create IAM roles in target accounts
2. ✅ Create IAM user in management account  
3. ✅ Create S3 buckets and DynamoDB tables
4. ✅ Configure GitHub secrets/variables
5. ✅ Update Terraform variables with role ARNs

The Terraform provider will automatically assume the correct role based on the environment.

## Quick AWS CLI Commands

If you prefer CLI over console:

```bash
# Create S3 bucket (in each account)
aws s3 mb s3://terraform-state-dev-retail-store --region us-east-1

# Create DynamoDB table (in each account)
aws dynamodb create-table \
  --table-name terraform-state-lock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## Test Your Setup

1. Uncomment the `assume_role_arn` lines in your `.tfvars` files
2. Push to `gitops` branch
3. Check GitHub Actions for successful execution
4. Verify resources in correct AWS accounts

## Benefits of This Approach

✅ **Simple** - No complex scripts or bootstrap processes
✅ **Secure** - Single credential set with assume role
✅ **Clean** - Minimal configuration files
✅ **Maintainable** - Easy to understand and modify
✅ **Scalable** - Easy to add more environments