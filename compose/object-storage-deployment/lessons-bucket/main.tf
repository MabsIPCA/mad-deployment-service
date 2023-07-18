# Plugin required to create buckets through minio.
terraform {
  required_providers {
    minio = {
      source = "aminueza/minio"
      version = "1.16.0"
    }
  }
}


# minio provider for creating buckets.
provider "minio" {
  minio_server = var.minio_server
  minio_user = var.minio_user
  minio_password = var.minio_password
  minio_ssl        = false
}
