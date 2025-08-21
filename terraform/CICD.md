# Terraform CI/CD Workflow (Simplified Multi-Account)

Simple multi-account Terraform workflow using assume role in the provider. No complex setup required!

## Overview

The Terraform workflow provides automated infrastructure management with:

- **Multi-account support** - Separate AWS accounts per environment
- **Assume role in provider** - Single credential set, Terraform handles cross-account access
- **Automated planning and applying** - Push to deploy
- **Pull request validation** - Plan and comment on PRs
- **Manual deployment controls** - Deploy any environment on demand

## Architecture

```
Management Account
├── GitHub Actions IAM User
└── sts:AssumeRole permissions

Dev Account (123456789012)
├── TerraformExecutionRole
├── S3: terraform-state-dev-retail-store
└── DynamoDB: terraform-state-lock-dev

Stage Account (987654321098)
├── TerraformExecutionRole
├── S3: terraform-state-stage-retail-store
└── DynamoDB: terraform-state-lock-stage
```

## Required Configuration

### GitHub Secrets (Only 2!)
- `AWS_ACCESS_KEY_ID` - Management account access key
- `AWS_SECRET_ACCESS_KEY` - Management account secret key

### GitHub Variables
- `AWS_REGION` - AWS region (e.g., us-east-1)

### Terraform Variables
Update your `.tfvars` files with assume role ARNs:

```hcl
# .env/dev/vars.tfvars
assume_role_arn = "arn:aws:iam::123456789012:role/TerraformExecutionRole"

# .env/stage/vars.tfvars
assume_role_arn = "arn:aws:iam::987654321098:role/TerraformExecutionRole"
```

## Workflow Triggers

### Automatic
- **Push to gitops** with terraform changes → Deploy to dev
- **Pull request** with terraform changes → Plan and comment

### Manual
- **Actions tab** → Choose environment and action (plan/apply/destroy)

## Setup Guide

See `SIMPLE-SETUP.md` for complete setup instructions.

## Benefits

✅ **Simple** - No bootstrap folders or shell scripts
✅ **Secure** - Single credential set with assume role
✅ **Clean** - Minimal configuration
✅ **Maintainable** - Easy to understand and modify
✅ **Scalable** - Easy to add more environments

## File Structure

```
terraform/
├── .env/
│   ├── dev/
│   │   ├── backend.tf      # S3 backend config
│   │   └── vars.tfvars     # Dev variables + assume role ARN
│   └── stage/
│       ├── backend.tf      # S3 backend config
│       └── vars.tfvars     # Stage variables + assume role ARN
├── main.tf                 # Infrastructure resources
├── variables.tf            # Variable definitions (includes assume_role_arn)
├── versions.tf             # Provider with assume_role block
└── SIMPLE-SETUP.md         # Setup instructions
```

## How It Works

1. **GitHub Actions** authenticates with management account credentials
2. **Terraform provider** assumes role in target account (dev/stage)
3. **All operations** run with assumed role permissions
4. **Resources created** in correct target account
5. **State stored** in target account S3 bucket

## Troubleshooting

### Common Issues

1. **AssumeRole Access Denied**
   - Check trust policy in target account role
   - Verify management account has sts:AssumeRole permission

2. **Backend Access Issues**
   - Ensure S3 bucket exists in target account
   - Verify DynamoDB table exists for state locking

3. **Permission Denied**
   - Check execution role has necessary permissions in target account

### Quick Fixes

```bash
# Test assume role manually
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/TerraformExecutionRole" \
  --role-session-name "test"

# Check current identity
aws sts get-caller-identity
```

This approach eliminates complexity while maintaining security and functionality!