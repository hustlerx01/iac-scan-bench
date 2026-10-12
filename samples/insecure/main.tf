# Deliberately insecure. Each planted issue is tagged PLANT-xx and listed in bench/ground_truth.yaml
terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = "ap-south-1" }

# PLANT-01 public-read ACL bucket
resource "aws_s3_bucket" "data" { bucket = "ansar-insecure-data" }
resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.data.id
  acl    = "public-read"
}
# PLANT-02 bucket public access block disabled
resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# PLANT-03 SSH open to world
resource "aws_security_group" "ssh" {
  name        = "ssh-open"
  description = "ssh"
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# PLANT-04 RDS public + unencrypted ; PLANT-05 hardcoded password
resource "aws_db_instance" "db" {
  identifier          = "legacy"
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "admin"
  password            = "SuperSecret123!"
  publicly_accessible = true
  storage_encrypted   = false
  skip_final_snapshot = true
}

# PLANT-06 unencrypted EBS volume
resource "aws_ebs_volume" "vol" {
  availability_zone = "ap-south-1a"
  size              = 10
  encrypted         = false
}

# PLANT-07 EC2 IMDSv1 allowed
resource "aws_instance" "web" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t3.micro"
  metadata_options {
    http_tokens = "optional"
  }
}

# PLANT-08 KMS key without rotation
resource "aws_kms_key" "k" { description = "no rotation" }

# PLANT-09 IAM policy with *:*
resource "aws_iam_policy" "admin" {
  name = "god-mode"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "*", Resource = "*" }]
  })
}

# PLANT-10 CloudTrail without log validation / KMS
resource "aws_cloudtrail" "t" {
  name                       = "trail"
  s3_bucket_name             = aws_s3_bucket.data.id
  enable_log_file_validation = false
}

# PLANT-11 hardcoded AWS key in provider-like locals (secret in IaC)
locals {
  legacy_key = "AKIAIOSFODNN7EXAMPLE"
}
