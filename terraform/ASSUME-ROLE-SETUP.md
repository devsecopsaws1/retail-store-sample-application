# Terraform with Assume Role in Provider

This approach uses a single set of base AWS credentials and assumes different roles for different environments using Terraform's `assume_role` block in the provider configuration.

## Architecture

```
Base AWS Account (Management/Security Account)
├── Base IAM User/Role (GitHub Actions credentials)
└── Cross-account assume role permissions

Target AWS Accounts
├── Dev Account (123456789012)
│   └── TerraformExecutionRole (assumable from base account)
└── Stage Account (987654321098)
    └── TerraformExecutionRole (assumable from base account)
```

## Benefits

✅ **Single credential set** - Only one set of AWS keys in GitHub
✅ **Centralized security** - All access controlled from base account
✅ **Easy rotation** - Only rotate base credentials
✅ **Audit trail** - Clear cross-account access logging
✅ **Terraform native** - Uses Terraform's built-in assume role capability

## Setup Steps

### Step 1: Create Base IAM User/Role

In your **management/security account**, create an IAM user or role with these permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": [
                "arn:aws:iam::123456789012:role/TerraformExecutionRole",
                "arn:aws:iam::987654321098:role/TerraformExecutionRole"
            ]
        }
    ]
}
```

### Step 2: Create Execution Roles in Target Accounts

In each **target account** (dev/stage), create a role named `TerraformExecutionRole`:

#### Trust Policy:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::MANAGEMENT-ACCOUNT-ID:user/github-actions-user"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "optional-external-id"
                }
            }
        }
    ]
}
```

#### Permissions Policy:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "iam:*",
                "kms:*",
                "cloudformation:*",
                "autoscaling:*",
                "elasticloadbalancing:*",
                "route53:*",
                "acm:*",
                "logs:*",
                "cloudwatch:*",
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetBucketVersioning",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::terraform-state-*",
                "arn:aws:s3:::terraform-state-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:DescribeTable"
            ],
            "Resource": [
                "arn:aws:dynamodb:*:*:table/terraform-state-lock-*"
            ]
        }
    ]
}
```

### Step 3: Update Terraform Variables

Update your environment-specific `.tfvars` files:

#### `terraform/.env/dev/vars.tfvars`:
```hcl
aws_region = "us-east-1"
cluster_name = "retail-store"
environment = "dev"
kubernetes_version = "1.33"
vpc_cidr = "10.0.0.0/16"
github_repository = "anikatech/retail-store-sample-app"
assume_role_arn = "arn:aws:iam::123456789012:role/TerraformExecutionRole"
# assume_role_external_id = "optional-external-id"
```

#### `terraform/.env/stage/vars.tfvars`:
```hcl
aws_region = "us-east-1"
cluster_name = "retail-store-stage"
environment = "stage"
kubernetes_version = "1.33"
vpc_cidr = "10.1.0.0/16"
enable_single_nat_gateway = false
enable_monitoring = true
github_repository = "anikatech/retail-store-sample-app"
assume_role_arn = "arn:aws:iam::987654321098:role/TerraformExecutionRole"
# assume_role_external_id = "optional-external-id"
```

### Step 4: Configure GitHub Secrets

**Repository Settings > Secrets and variables > Actions > Secrets:**

- `AWS_ACCESS_KEY_ID`: Base account access key
- `AWS_SECRET_ACCESS_KEY`: Base account secret key

**Repository Settings > Secrets and variables > Actions > Variables:**

- `AWS_REGION`: `us-east-1`

### Step 5: Test the Setup

1. Uncomment the `assume_role_arn` lines in your `.tfvars` files
2. Push changes to the `gitops` branch
3. Check GitHub Actions for successful execution
4. Verify resources are created in the correct target accounts

## How It Works

1. **GitHub Actions** authenticates with base AWS credentials
2. **Terraform provider** assumes the role specified in `assume_role_arn`
3. **All Terraform operations** run with the assumed role's permissions
4. **Resources are created** in the target account (dev/stage)

## Terraform Provider Configuration

The provider automatically handles role assumption:

```hcl
provider "aws" {
  region = var.aws_region
  
  dynamic "assume_role" {
    for_each = var.assume_role_arn != null ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = "terraform-${var.environment}"
      external_id  = var.assume_role_external_id
    }
  }
}
```

## Comparison with OIDC

| Feature | Assume Role | OIDC |
|---------|-------------|------|
| **Credentials in GitHub** | 1 set (base account) | 0 (no keys) |
| **Setup Complexity** | Medium | High |
| **Security** | Good | Excellent |
| **Credential Rotation** | Manual (base only) | Automatic |
| **Cross-Account** | Native support | Requires per-account setup |
| **Audit Trail** | Clear assume role logs | OIDC token logs |

## Troubleshooting

### Common Issues:

1. **AssumeRole Access Denied**
   - Check trust policy in target account role
   - Verify base account has `sts:AssumeRole` permission
   - Ensure role ARN is correct in `.tfvars`

2. **External ID Mismatch**
   - Verify external ID matches in trust policy and `.tfvars`
   - External ID is optional but adds security

3. **Session Name Issues**
   - Session names must be unique and follow AWS naming rules
   - Current format: `terraform-${environment}`

4. **Permission Denied in Target Account**
   - Check the execution role has necessary permissions
   - Verify resource ARNs in policy statements

### Debugging Commands:

```bash
# Test assume role manually
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/TerraformExecutionRole" \
  --role-session-name "test-session"

# Check current identity
aws sts get-caller-identity

# Test Terraform assume role
cd terraform
terraform console
> data.aws_caller_identity.current.account_id
```

## Security Best Practices

1. **Use External ID** for additional security
2. **Rotate base credentials** regularly
3. **Monitor assume role usage** via CloudTrail
4. **Limit session duration** in trust policy
5. **Use least privilege** permissions in execution roles
6. **Enable MFA** for base account (if using IAM user)

This approach provides a good balance between security and simplicity, especially when you have a centralized security/management account structure.