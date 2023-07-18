# region for aws and minio
variable "region" {
  description = "Default region"
  default = "us-east-1"
}

# server location for local minio server
# TODO: Update the minio server to s3.mad.localhost
variable "minio_server" {
  description = "Default MINIO host and port"
  default = "localhost:9000"
}

# access key
variable "minio_user" {
  description = "User"
  default = "minio"
}

# secret key
variable "minio_password" {
  description = "Secret password"
  default = "minio123"
}