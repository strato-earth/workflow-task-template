
data "aws_iam_policy_document" "workflow_task_assume" {
  for_each = local.workflow_tasks_repos
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${each.value}:*"]
    }
  }
}

resource "aws_iam_role" "workflow_task" {
  for_each           = local.workflow_tasks_repos
  name               = "github-build-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.workflow_task_assume[each.key].json
}

data "aws_iam_policy_document" "workflow_task" {
  for_each = local.workflow_tasks_repos
  statement {
    sid    = "GetWrapper"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.workflow_task_artifacts.id}/strato-workflow-tasks-wrapper/strato-workflow-tasks-wrapper.zip"]
  }

  statement {
    sid    = "PutObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.workflow_task_artifacts.id}/${each.key}/*"]
  }

  # statement {
  #   sid    = "PushImage"
  #   effect = "Allow"
  #   actions = [
  #     "ecr:GetAuthorizationToken",
  #     "ecr:BatchCheckLayerAvailability",
  #     "ecr:GetDownloadUrlForLayer",
  #     "ecr:GetRepositoryPolicy",
  #     "ecr:DescribeRepositories",
  #     "ecr:ListImages",
  #     "ecr:DescribeImages",
  #     "ecr:BatchGetImage",
  #     "ecr:GetLifecyclePolicy",
  #     "ecr:GetLifecyclePolicyPreview",
  #     "ecr:ListTagsForResource",
  #     "ecr:DescribeImageScanFindings",
  #     "ecr:InitiateLayerUpload",
  #     "ecr:UploadLayerPart",
  #     "ecr:CompleteLayerUpload",
  #     "ecr:PutImage"
  #   ]
  #   resources = [for account in local.workflow_accounts : "arn:aws:ecr:*:${account}:repository/${each.key}"]
  # }

  # Permissions to push images only to the current account
  statement {
    sid    = "PushImage"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["arn:aws:ecr:*:${local.account_id}:repository/${each.key}"]
  }

  # Permissions to pull images (read-only) across specified accounts
  statement {
    sid    = "PullImageAcrossAccounts"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage"
    ]
    resources = [for account in local.workflow_accounts : "arn:aws:ecr:*:${account}:repository/${each.key}"]
  }

  statement {
    sid    = "LoginToECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SSMGetAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/strato/${var.environment}/config/workflow_accounts"
    ]
  }

  statement {
    sid    = "InvokeWorkflowTaskUpdateFunction"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [for account in local.workflow_accounts : "arn:aws:lambda:*:${account}:function:strato-update-workflow-task"]
  }
}

resource "aws_iam_policy" "workflow_task" {
  for_each = local.workflow_tasks_repos
  name     = "github-build-strato-${replace(each.value, "/", "-")}"
  policy   = data.aws_iam_policy_document.workflow_task[each.key].json
}

resource "aws_iam_role_policy_attachment" "workflow_task" {
  for_each   = local.workflow_tasks_repos
  role       = aws_iam_role.workflow_task[each.key].name
  policy_arn = aws_iam_policy.workflow_task[each.key].arn
}
