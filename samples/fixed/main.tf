# Hardened counterpart of samples/insecure/main.tf
terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = "ap-south-1" }

variable "db_password" {
  type      = string
  sensitive = true
}
variable "admin_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

resource "aws_kms_key" "k" {
  description         = "rotated"
  enable_key_rotation = true
}

resource "aws_s3_bucket" "data" { bucket = "ansar-secure-data" }
resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.k.arn
    }
  }
}
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_security_group" "ssh" {
  name        = "ssh-admin"
  description = "ssh from admin network only"
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }
}

resource "aws_db_instance" "db" {
  identifier                 = "legacy"
  engine                     = "mysql"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  username                   = "admin"
  password                   = var.db_password
  publicly_accessible        = false
  storage_encrypted          = true
  kms_key_id                 = aws_kms_key.k.arn
  deletion_protection        = true
  skip_final_snapshot        = false
}

resource "aws_ebs_volume" "vol" {
  availability_zone = "ap-south-1a"
  size              = 10
  encrypted         = true
  kms_key_id        = aws_kms_key.k.arn
}

resource "aws_instance" "web" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t3.micro"
  metadata_options {
    http_tokens = "required"
  }
  root_block_device { encrypted = true }
}

resource "aws_iam_policy" "readonly" {
  name = "s3-read-data"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = ["s3:GetObject"], Resource = "${aws_s3_bucket.data.arn}/*" }]
  })
}

resource "aws_cloudtrail" "t" {
  name                       = "trail"
  s3_bucket_name             = aws_s3_bucket.data.id
  enable_log_file_validation = true
  is_multi_region_trail      = true
  kms_key_id                 = aws_kms_key.k.arn
}
