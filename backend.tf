# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "limanEKS-terraform-statefile"

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_dynamodb_table" "limanEKS_terraform_locks" {
#   name         = "limanEKS-terraform-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = {
#     Name = "Moonlite DynamoDB Terraform State Lock"
#   }
# }
