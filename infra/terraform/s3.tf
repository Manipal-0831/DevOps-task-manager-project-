resource "aws_s3_bucket" "task_manager" {
  bucket = "task-manager-bucket"
  force_destroy = true   # allows safe cleanup later 
}
