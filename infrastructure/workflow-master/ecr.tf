resource "aws_ecr_repository" "main" {
  for_each = local.workflow_tasks_repos
  name     = each.key

  image_scanning_configuration {
    scan_on_push = true
  }
}
