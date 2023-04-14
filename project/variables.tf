variable "stream_name" {
  description = "Kinesis data stream name"
  type        = string
  default     = "stream_auto"
}

variable "bucket_name" {
  description = "S3 bucket name to store data"
  type        = string
  default     = "tarassitohwbucket"
}