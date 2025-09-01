#!/bin/bash
set -e

echo "🔹 Creating S3 bucket in LocalStack..."

aws --endpoint-url=http://localhost:4566 s3 mb s3://task-manager-bucket

echo "✅ S3 bucket created: task-manager-bucket"

