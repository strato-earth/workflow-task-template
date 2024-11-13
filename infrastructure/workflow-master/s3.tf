resource "aws_s3_bucket" "workflow_task_artifacts" {
  bucket = "${local.name}-workflow-task-artifacts"

  force_destroy = false

  tags = {
    Name      = "${local.name} Workflow Task Artifacts Bucket"
    Security  = "SSE:AWS"
    Terraform = "true"
  }
}

resource "aws_s3_bucket_ownership_controls" "workflow_task_artifacts" {
  bucket = aws_s3_bucket.workflow_task_artifacts.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "workflow_task_artifacts" {
  bucket = aws_s3_bucket.workflow_task_artifacts.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.workflow_task_artifacts,
    aws_s3_bucket_public_access_block.workflow_task_artifacts
  ]
}

resource "aws_s3_bucket_public_access_block" "workflow_task_artifacts" {
  depends_on = [aws_s3_bucket.workflow_task_artifacts]
  bucket     = aws_s3_bucket.workflow_task_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "workflow_task_artifacts" {
  bucket = aws_s3_bucket.workflow_task_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# resource "aws_s3_bucket_logging" "workflow_task_artifacts" {
#   bucket = aws_s3_bucket.workflow_task_artifacts.id

#   target_bucket = aws_s3_bucket.workflow_task_artifacts_logs.id
#   target_prefix = "AWSLogs/${local.account_id}/S3/${local.name}-workflow-task-artifacts/"
# }

resource "aws_s3_bucket_server_side_encryption_configuration" "workflow_task_artifacts" {
  bucket = aws_s3_bucket.workflow_task_artifacts.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "workflow_task_artifacts" {
  policy_id = "${aws_s3_bucket.workflow_task_artifacts.id}-policy"
  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.workflow_task_artifacts.arn,
      "${aws_s3_bucket.workflow_task_artifacts.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }

  statement {
    sid    = "AllowCrossAccountGetAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.workflow_task_artifacts.arn,
      "${aws_s3_bucket.workflow_task_artifacts.arn}/*"
    ]
    principals {
      identifiers = [for account in local.workflow_accounts : "arn:aws:iam::${account}:root"]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "workflow_task_artifacts" {
  depends_on = [aws_s3_bucket_public_access_block.workflow_task_artifacts]
  bucket     = aws_s3_bucket.workflow_task_artifacts.id
  policy     = data.aws_iam_policy_document.workflow_task_artifacts.json
}
