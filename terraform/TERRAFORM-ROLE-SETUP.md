# TerraformExecutionRole Setup Guide

Complete step-by-step guide to create the `TerraformExecutionRole` with proper permissions for EKS infrastructure deployment.

## Required Permissions

The `TerraformExecutionRole` needs permissions to create and manage:
- EKS clusters and node groups
- VPC, subnets, security groups, and networking
- IAM roles and policies
- S3 buckets and DynamoDB tables (for state)
- Load balancers and auto scaling groups
- KMS keys for encryption
- CloudWatch logs and monitoring

## Step-by-Step Setup

### Step 1: Create the IAM Role

#### Option A: AWS Console

1. **Go to IAM Console** → **Roles** → **Create role**
2. **Select trusted entity**: Custom trust policy
3. **Trust policy**: Paste the JSON below (replace `MANAGEMENT-ACCOUNT-ID`)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::MANAGEMENT-ACCOUNT-ID:user/github-actions"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "terraform-execution"
                }
            }
        }
    ]
}
```

4. **Role name**: `TerraformExecutionRole`
5. **Description**: `Role for Terraform to manage EKS infrastructure via GitHub Actions`

#### Option B: AWS CLI

```bash
# Create trust policy file
cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::MANAGEMENT-ACCOUNT-ID:user/github-actions"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "terraform-execution"
                }
            }
        }
    ]
}
EOF

# Create the role
aws iam create-role \
    --role-name TerraformExecutionRole \
    --assume-role-policy-document file://trust-policy.json \
    --description "Role for Terraform to manage EKS infrastructure via GitHub Actions"
```

### Step 2: Create Custom Policy for Terraform

#### Option A: AWS Console

1. **Go to IAM Console** → **Policies** → **Create policy**
2. **JSON tab**: Paste the policy below
3. **Policy name**: `TerraformEKSPolicy`
4. **Description**: `Comprehensive permissions for Terraform EKS deployment`

#### Option B: AWS CLI

```bash
# Create the policy
aws iam create-policy \
    --policy-name TerraformEKSPolicy \
    --policy-document file://terraform-policy.json \
    --description "Comprehensive permissions for Terraform EKS deployment"
```

### Step 3: Terraform Policy JSON

Create `terraform-policy.json` with these permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EKSPermissions",
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EC2NetworkingPermissions",
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMPermissions",
            "Effect": "Allow",
            "Action": [
                "iam:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AutoScalingPermissions",
            "Effect": "Allow",
            "Action": [
                "autoscaling:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "LoadBalancerPermissions",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "KMSPermissions",
            "Effect": "Allow",
            "Action": [
                "kms:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudFormationPermissions",
            "Effect": "Allow",
            "Action": [
                "cloudformation:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "LogsPermissions",
            "Effect": "Allow",
            "Action": [
                "logs:*",
                "cloudwatch:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Route53Permissions",
            "Effect": "Allow",
            "Action": [
                "route53:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CertificateManagerPermissions",
            "Effect": "Allow",
            "Action": [
                "acm:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "TerraformStatePermissions",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetBucketVersioning",
                "s3:GetBucketLocation",
                "s3:CreateBucket",
                "s3:PutBucketVersioning",
                "s3:PutBucketEncryption",
                "s3:PutBucketPublicAccessBlock"
            ],
            "Resource": [
                "arn:aws:s3:::terraform-state-*",
                "arn:aws:s3:::terraform-state-*/*"
            ]
        },
        {
            "Sid": "DynamoDBStatePermissions",
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:DescribeTable",
                "dynamodb:CreateTable",
                "dynamodb:UpdateTable",
                "dynamodb:ListTables"
            ],
            "Resource": [
                "arn:aws:dynamodb:*:*:table/terraform-state-lock-*"
            ]
        },
        {
            "Sid": "STSPermissions",
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity",
                "sts:AssumeRole"
            ],
            "Resource": "*"
        },
        {
            "Sid": "TaggingPermissions",
            "Effect": "Allow",
            "Action": [
                "tag:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### Step 4: Attach Policy to Role

#### Option A: AWS Console
1. **Go to IAM Console** → **Roles** → **TerraformExecutionRole**
2. **Permissions tab** → **Add permissions** → **Attach policies**
3. **Search and select**: `TerraformEKSPolicy`
4. **Attach policy**

#### Option B: AWS CLI
```bash
# Get the policy ARN (replace ACCOUNT-ID)
POLICY_ARN="arn:aws:iam::ACCOUNT-ID:policy/TerraformEKSPolicy"

# Attach policy to role
aws iam attach-role-policy \
    --role-name TerraformExecutionRole \
    --policy-arn $POLICY_ARN
```

### Step 5: Create S3 Bucket and DynamoDB Table

#### S3 Bucket for Terraform State
```bash
# Replace ENV with 'dev' or 'stage'
ENV="dev"
BUCKET_NAME="terraform-state-${ENV}-retail-store"

# Create bucket
aws s3 mb s3://${BUCKET_NAME} --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket ${BUCKET_NAME} \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket ${BUCKET_NAME} \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
aws s3api put-public-access-block \
    --bucket ${BUCKET_NAME} \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

#### DynamoDB Table for State Locking
```bash
# Replace ENV with 'dev' or 'stage'
ENV="dev"
TABLE_NAME="terraform-state-lock-${ENV}"

# Create table
aws dynamodb create-table \
    --table-name ${TABLE_NAME} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

## Complete Setup Script

Here's a complete script to set up everything in one go:

```bash
#!/bin/bash

# Configuration
MANAGEMENT_ACCOUNT_ID="111111111111"  # Replace with your management account ID
CURRENT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ENV="dev"  # Change to 'stage' for staging account
REGION="us-east-1"

echo "Setting up TerraformExecutionRole in account: ${CURRENT_ACCOUNT_ID}"
echo "Management account: ${MANAGEMENT_ACCOUNT_ID}"
echo "Environment: ${ENV}"

# 1. Create trust policy
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${MANAGEMENT_ACCOUNT_ID}:user/github-actions"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "terraform-execution"
                }
            }
        }
    ]
}
EOF

# 2. Create the role
aws iam create-role \
    --role-name TerraformExecutionRole \
    --assume-role-policy-document file://trust-policy.json \
    --description "Role for Terraform to manage EKS infrastructure via GitHub Actions"

# 3. Attach AWS managed policies (for simplicity, use AdministratorAccess)
aws iam attach-role-policy \
    --role-name TerraformExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# 4. Create S3 bucket
BUCKET_NAME="terraform-state-${ENV}-retail-store"
aws s3 mb s3://${BUCKET_NAME} --region ${REGION}
aws s3api put-bucket-versioning --bucket ${BUCKET_NAME} --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket ${BUCKET_NAME} --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
}'
aws s3api put-public-access-block --bucket ${BUCKET_NAME} --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 5. Create DynamoDB table
TABLE_NAME="terraform-state-lock-${ENV}"
aws dynamodb create-table \
    --table-name ${TABLE_NAME} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ${REGION}

# 6. Output role ARN
ROLE_ARN="arn:aws:iam::${CURRENT_ACCOUNT_ID}:role/TerraformExecutionRole"
echo ""
echo "✅ Setup completed!"
echo "Role ARN: ${ROLE_ARN}"
echo "S3 Bucket: ${BUCKET_NAME}"
echo "DynamoDB Table: ${TABLE_NAME}"
echo ""
echo "Add this to your terraform/.env/${ENV}/vars.tfvars:"
echo "assume_role_arn = \"${ROLE_ARN}\""

# Cleanup
rm trust-policy.json
```

## Security Considerations

### Production Recommendations:
1. **Use custom policy** instead of `AdministratorAccess` for least privilege
2. **Add external ID** for additional security
3. **Enable CloudTrail** to audit assume role usage
4. **Set session duration** limits in trust policy
5. **Use condition keys** to restrict access (IP, time, etc.)

### Example Enhanced Trust Policy:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::MANAGEMENT-ACCOUNT-ID:user/github-actions"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "terraform-execution"
                },
                "NumericLessThan": {
                    "aws:TokenIssueTime": "3600"
                }
            }
        }
    ]
}
```

## Verification

Test the setup:

```bash
# From management account, test assume role
aws sts assume-role \
    --role-arn "arn:aws:iam::TARGET-ACCOUNT:role/TerraformExecutionRole" \
    --role-session-name "test-session" \
    --external-id "terraform-execution"

# Should return temporary credentials
```

## Next Steps

1. ✅ Run this setup in both dev and stage accounts
2. ✅ Update your `.tfvars` files with the role ARNs
3. ✅ Configure GitHub secrets with management account credentials
4. ✅ Test the Terraform workflow

You're now ready to deploy infrastructure across multiple AWS accounts securely!