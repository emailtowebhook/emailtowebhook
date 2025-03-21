#!/bin/bash
set -e

echo "🧹 Starting cleanup process..."

# Change to the infrastructure directory
cd infra

# Create empty lambda package directories if they don't exist
echo "📦 Creating placeholder Lambda packages if needed..."
mkdir -p ../lambda_packages

# Create empty zip files if they don't exist
if [ ! -f "../lambda_packages/check.zip" ]; then
  echo "Creating placeholder check.zip file..."
  touch dummy_file
  zip -q ../lambda_packages/check.zip dummy_file
  rm dummy_file
fi

if [ ! -f "../lambda_packages/parser.zip" ]; then
  echo "Creating placeholder parser.zip file..."
  touch dummy_file
  zip -q ../lambda_packages/parser.zip dummy_file
  rm dummy_file
fi

 

# Get bucket names from Terraform state safely
echo "📋 Retrieving bucket information from variables.tf..."
PARSER_BUCKET=$(grep -A2 "database_bucket_name" variables.tf | grep "default" | awk -F'"' '{print $2}')
ATTACHMENTS_BUCKET=$(grep -A2 "attachments_bucket_name" variables.tf | grep "default" | awk -F'"' '{print $2}')
emails_bucket=$(grep -A2 "email_bucket_name" variables.tf | grep "default" | awk -F'"' '{print $2}')

# Function to empty an S3 bucket safely
empty_bucket() {
  local bucket_name=$1
  if [[ "$bucket_name" == "NOT_FOUND" || -z "$bucket_name" ]]; then
    echo "⚠️  Skipping bucket cleanup. No bucket found in Terraform state."
  else
    echo "🗑️  Emptying bucket: $bucket_name"
    aws s3 rb s3://$bucket_name --force || echo "⚠️  Warning: Failed to empty bucket $bucket_name"
  fi
}

# Empty buckets if they exist
empty_bucket "$PARSER_BUCKET"
empty_bucket "$emails_bucket"
empty_bucket "$ATTACHMENTS_BUCKET"

# Run terraform destroy
echo "💥 Running terraform destroy..."
terraform destroy -auto-approve

# Clean up the placeholder files
echo "🧹 Cleaning up placeholder files..."
rm -rf ../lambda_packages

echo "✅ Cleanup complete! All resources have been destroyed."
