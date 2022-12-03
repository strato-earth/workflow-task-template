resource "aws_ecr_repository" "main" {
  name = var.repo_name  

  image_scanning_configuration {
    scan_on_push = true
  }
}

# resource "aws_ecr_repository_policy" "main" {
#   repository = aws_ecr_repository.main.name

#   policy = <<POLICY
# {
#     "Version": "2008-10-17",
#     "Statement": [
#         {
#             "Sid": "new policy",
#             "Effect": "Allow",
#             "Principal":{
#               "AWS": ${jsonencode(local.allowed_arns)}
#             },
#             "Action": "ecr:*"
#         }
#     ]
# }
# POLICY
# }
