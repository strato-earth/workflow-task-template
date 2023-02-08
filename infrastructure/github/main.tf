data "aws_iam_policy_document" "github_strato_workflow_task_deployer_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_organization}/${var.repo_name}:*"]
    }
  }
}

resource "aws_iam_role" "github_strato_workflow_task_deployer" {
  name               = "github-build-${var.repo_name}"
  assume_role_policy = data.aws_iam_policy_document.github_strato_workflow_task_deployer_assume.json
}

data "aws_iam_policy_document" "github_strato_workflow_task_deployer" {
  statement {
    sid    = "PutObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::${var.build_artifacts_bucket}/${var.task_type}/${var.repo_name}/*"]
  }

  statement {
    sid    = "PushImage"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["arn:aws:ecr:*:${local.account_id}:repository/${var.repo_name}"]
  }

  statement {
    sid    = "LoginToECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }  
}

resource "aws_iam_policy" "github_strato_workflow_task_deployer" {
  name   = "github-build-strato-${var.github_organization}-${var.repo_name}"
  policy = data.aws_iam_policy_document.github_strato_workflow_task_deployer.json
}

resource "aws_iam_role_policy_attachment" "github_strato_workflow_task_deployer" {
  role       = aws_iam_role.github_strato_workflow_task_deployer.name
  policy_arn = aws_iam_policy.github_strato_workflow_task_deployer.arn
}
