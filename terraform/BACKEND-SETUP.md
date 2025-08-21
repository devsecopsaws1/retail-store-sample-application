# Terraform S3 Backend Configuration

This explains how the S3 backend is configured for multi-environment deployments.

## Backend Configuration Structure

### Main Configuration (versions.tf)
```hcl
terraform {
  # Empty S3 backend block - configuration provided via -backend-config
  backend "s3" {
    # Configuration will be provided via .env/{environment}/backend.tf files
  }
}
```

### Environment-Specific Backend Config Files

#### `.env/dev/backend.tf`
```hcl
bucket = "terraform-state-dev-retail-store"
key    = "dev/terraform.state"
region = "us-east-1"
encrypt = true
dynamodb_table = "terraform-state-lock-dev"
```

#### `.env/stage/backend.tf`
```hcl
bucket = "terraform-state-stage-retail-store"
key    = "stage/terraform.state"
region = "us-east-1"
encrypt = true
dynamodb_table = "terraform-state-lock-stage"
```

## How It Works

### 1. During Terraform Init
The GitHub Actions workflow runs:
```bash
terraform init -backend-config=".env/${ENV}/backend.tf"
```

### 2. Backend Configuration Applied
Terraform reads the backend config file and configures the S3 backend with:
- **Bucket**: Environment-specific S3 bucket
- **Key**: Path within the bucket for the state file
- **Region**: AWS region
- **Encrypt**: Enable server-side encryption
- **DynamoDB Table**: Table for state locking

### 3. State Management
- **Dev environment**: State stored in `terraform-state-dev-retail-store` bucket
- **Stage environment**: State stored in `terraform-state-stage-retail-store` bucket
- **Locking**: Prevents concurrent modifications using DynamoDB

## Benefits of This Approach

✅ **Environment Isolation**: Each environment has its own state file and bucket
✅ **Security**: State files are encrypted and access-controlled per account
✅ **Locking**: DynamoDB prevents concurrent Terraform runs
✅ **Flexibility**: Easy to add new environments by creating new backend config files
✅ **Clean**: No hardcoded values in main Terraform configuration

## Required AWS Resources

For each environment, you need:

### S3 Bucket
- **Name**: `terraform-state-{env}-retail-store`
- **Versioning**: Enabled
- **Encryption**: AES-256 or KMS
- **Public Access**: Blocked

### DynamoDB Table
- **Name**: `terraform-state-lock-{env}`
- **Partition Key**: `LockID` (String)
- **Billing**: On-demand or provisioned

## Workflow Integration

The GitHub Actions workflow automatically:

1. **Determines environment** (dev/stage)
2. **Selects backend config** (`.env/{env}/backend.tf`)
3. **Initializes Terraform** with the correct backend
4. **Assumes role** in the target account
5. **Manages state** in the environment-specific S3 bucket

## Example Workflow Steps

```yaml
- name: Terraform Init
  run: |
    cd terraform
    ENV="${{ needs.detect-changes.outputs.environment }}"
    BACKEND_CONFIG=".env/${ENV}/backend.tf"
    terraform init -backend-config="${BACKEND_CONFIG}"
```

## Verification

You can verify the backend configuration:

```bash
# Check current backend configuration
terraform show -json | jq '.values.root_module.resources[] | select(.type == "terraform_remote_state")'

# List state files in S3
aws s3 ls s3://terraform-state-dev-retail-store/

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-state-lock-dev
```

## Troubleshooting

### Common Issues:

1. **Backend bucket doesn't exist**
   ```
   Error: Failed to get existing workspaces: S3 bucket does not exist
   ```
   **Solution**: Create the S3 bucket in the target account

2. **DynamoDB table doesn't exist**
   ```
   Error: Error locking state: Error acquiring the state lock
   ```
   **Solution**: Create the DynamoDB table in the target account

3. **Permission denied**
   ```
   Error: Error loading state: AccessDenied
   ```
   **Solution**: Ensure the assumed role has S3 and DynamoDB permissions

4. **Wrong account**
   ```
   Error: The specified bucket does not exist
   ```
   **Solution**: Verify you're assuming the correct role for the target account

This backend configuration ensures secure, isolated state management across multiple AWS accounts and environments!