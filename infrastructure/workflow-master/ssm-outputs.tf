resource "aws_ssm_parameter" "oidc_provider_arn" {
  name        = "/strato/${var.environment}/config/workflow-master/oidc_provider_arn"
  description = "OIDC Provider ARN for ${var.environment}"
  type        = "String"
  value       = local.oidc_provider_arn
}

resource "aws_ssm_parameter" "workflow_task_artifacts_bucket" {
  name        = "/strato/${var.environment}/config/workflow-master/workflow_task_artifacts_bucket"
  description = "Workflow Task Artifacts Bucket for ${var.environment}"
  type        = "String"
  value       = aws_s3_bucket.workflow_task_artifacts.id
}