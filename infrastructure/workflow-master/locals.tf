data "aws_caller_identity" "current" {
}

locals {
  account_id           = data.aws_caller_identity.current.account_id
  name                 = "${var.name}-${var.environment}"
  workflow_accounts    = split(",", var.workflow_accounts)
  workflow_tasks_repos = var.workflow_tasks_repos == "" ? {} : { for repo in split(",", var.workflow_tasks_repos) : split("/", repo)[1] => repo }
  oidc_provider_arn    = var.oidc_provider_arn == "" ? aws_iam_openid_connect_provider.github[0].arn : var.oidc_provider_arn
}
