resource "minio_s3_bucket" "bucket" {
bucket = "mad-images"
acl = "public"
}