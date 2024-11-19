resource "aws_ecr_repository" "main" {
  for_each = local.workflow_tasks_repos
  name     = each.key

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_iam_policy_document" "ecr_pull_policy" {
  for_each = local.workflow_tasks_repos

  statement {
    sid    = "AllowPullAccessForWorkflowAccounts"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.workflow_accounts
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}

resource "aws_ecr_repository_policy" "main" {
  for_each   = local.workflow_tasks_repos
  repository = aws_ecr_repository.main[each.key].name

  policy = data.aws_iam_policy_document.ecr_pull_policy[each.key].json
}
