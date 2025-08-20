# GitHub Actions CI/CD Workflows

This directory contains GitHub Actions workflows for the retail store sample application's CI/CD pipeline. Each microservice has its own dedicated workflow that automatically builds, pushes Docker images to Amazon ECR, and updates Helm chart values for GitOps deployment.

## 🚀 Workflows Overview

| Workflow | Service | Trigger Path | ECR Repository |
|----------|---------|--------------|----------------|
| `ci-ui.yml` | UI Service | `src/ui/**` | `retail-store-ui` |
| `ci-catalog.yml` | Catalog Service | `src/catalog/**` | `retail-store-catalog` |
| `ci-cart.yml` | Cart Service | `src/cart/**` | `retail-store-cart` |
| `ci-orders.yml` | Orders Service | `src/orders/**` | `retail-store-orders` |
| `ci-checkout.yml` | Checkout Service | `src/checkout/**` | `retail-store-checkout` |

## 📋 Prerequisites

### Required GitHub Secrets

Configure the following secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID for ECR access | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key for ECR access | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS region where ECR repositories are located | `us-east-1` |

### AWS IAM Permissions

The AWS credentials must have the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage",
                "ecr:CreateRepository",
                "ecr:DescribeRepositories"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🔄 How It Works

### 1. Change Detection
- Each workflow monitors specific paths using GitHub Actions path filters
- Only the relevant service workflow runs when changes are detected
- Multiple services can build concurrently if changed simultaneously

### 2. Docker Build Process
- Workflows use the existing Dockerfiles in each service directory
- Images are tagged with the Git commit SHA for traceability
- Docker layer caching is utilized for faster builds

### 3. ECR Integration
- Automatic ECR repository creation if it doesn't exist
- Secure authentication using AWS credentials from GitHub Secrets
- Images are pushed with commit SHA tags

### 4. Helm Values Update
- Automatically updates `values.yaml` files with new image repository and tag
- Changes are committed back to the repository
- ArgoCD detects changes and syncs to Kubernetes cluster

### 5. GitOps Flow
```mermaid
graph LR
    A[Code Push] --> B[GitHub Actions]
    B --> C[Build Image]
    C --> D[Push to ECR]
    D --> E[Update Helm Values]
    E --> F[Commit Changes]
    F --> G[ArgoCD Sync]
    G --> H[Kubernetes Deploy]
```

## 🛠️ Manual Triggers

All workflows can be manually triggered using the `workflow_dispatch` event:

1. Go to `Actions` tab in your GitHub repository
2. Select the desired workflow
3. Click `Run workflow`
4. Choose the branch and click `Run workflow`

## 📊 Workflow Status

Each workflow provides detailed status information:

- **Build Summary**: Shows service name, image details, and updated charts
- **Step-by-step Logs**: Detailed logs for troubleshooting
- **Artifacts**: Build outputs and deployment information

## 🔧 Customization

### Adding New Services

To add a new service workflow:

1. Copy an existing workflow file (e.g., `ci-ui.yml`)
2. Update the following variables:
   - Workflow name
   - `paths` filter for the new service
   - `ECR_REPOSITORY` name
   - `SERVICE_NAME` variable

### Modifying Build Process

Each workflow can be customized for specific build requirements:

- **Build Arguments**: Add Docker build args in the build step
- **Multi-stage Builds**: Leverage existing Dockerfiles' multi-stage builds
- **Testing**: Add test steps before the build process
- **Security Scanning**: Add container vulnerability scanning

## 🚨 Troubleshooting

### Common Issues

1. **AWS Authentication Failures**
   - Verify GitHub Secrets are correctly configured
   - Check IAM permissions for the AWS user
   - Ensure AWS region is correct

2. **Docker Build Failures**
   - Check Dockerfile syntax and dependencies
   - Verify build context and file paths
   - Review build logs for specific errors

3. **ECR Push Failures**
   - Confirm ECR repository exists or can be created
   - Check network connectivity to ECR
   - Verify image size limits

4. **Helm Values Update Issues**
   - Ensure `values.yaml` file exists in the correct path
   - Check file permissions and Git configuration
   - Verify commit and push permissions

### Debug Mode

Enable debug logging by adding this secret to your repository:
- `ACTIONS_STEP_DEBUG`: `true`

## 📈 Monitoring and Metrics

Monitor your CI/CD pipeline through:

- **GitHub Actions Dashboard**: View workflow runs and success rates
- **AWS CloudWatch**: Monitor ECR repository metrics
- **ArgoCD UI**: Track deployment status and sync health
- **Kubernetes Dashboard**: Monitor application deployment status

## 🔒 Security Best Practices

- Use GitHub Secrets for all sensitive information
- Regularly rotate AWS credentials
- Enable ECR image scanning for vulnerabilities
- Use least privilege IAM policies
- Monitor workflow logs for security issues

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)