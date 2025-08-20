# IAM User for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "github-actions-ecr-user"
  path = "/"
}

# IAM Policy for ECR operations
resource "aws_iam_policy" "github_ecr_policy" {
  name        = "GitHubActionsECRPolicy"
  description = "Policy for GitHub Actions to push images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:CreateRepository",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/retail-store-*"
      }
    ]
  })
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "github_ecr_attach" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.github_ecr_policy.arn
}

# Create access keys
resource "aws_iam_access_key" "github_actions_key" {
  user = aws_iam_user.github_actions.name
}



# Outputs for GitHub secrets
output "github_aws_access_key_id" {
  value     = aws_iam_access_key.github_actions_key.id
  sensitive = false
}

output "github_aws_secret_access_key" {
  value     = aws_iam_access_key.github_actions_key.secret
  sensitive = true
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}