variable "name" {
  type = string
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "profile" {
  type        = string
  description = "AWS Profile"
  default     = null
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "workflow_tasks_repos" {
  type        = string
  description = "Github Repos for workflow tasks"
  default     = ""
}

variable "workflow_accounts" {
  type        = string
  description = "AWS accounts with access to workflow tasks artifacts"
  default     = ""
}

variable "oidc_provider_arn" {
  type        = string
  description = "GitHub OIDC Provider ARN"
  default     = ""
}
