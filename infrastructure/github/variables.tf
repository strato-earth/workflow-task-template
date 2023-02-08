variable "environment" {
  type        = string
  description = "Environment name"
}

variable "profile" {
  type        = string
  description = "AWS Profile"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "github_organization" {
  type        = string
  description = "GitHub Organization"
}

variable "repo_name" {
  type        = string
  description = "GitHub Repo Name"
}

variable "oidc_provider_arn" {
  type        = string
  description = "GitHub OIDC Provider ARN"
}

variable "build_artifacts_bucket" {
  type        = string
  description = "Build Artifacts Bucket"
}

variable "task_type" {
  type        = string
  description = "The Workflow task type"
}