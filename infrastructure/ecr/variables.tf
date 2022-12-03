variable "environment" {
  type        = string
  description = "Environment name"
}

variable "profile" {
  type = string
  description = "AWS Profile"  
}

variable "region" {
  type = string
  description = "AWS Region"
}

variable "repo_name" {
  type = string
  description = "ECR Repo Name"
}