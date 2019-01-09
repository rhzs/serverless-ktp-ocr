variable "project" {
  default = "ektp-ocr"
}

variable "region" {
  default = "asia-northeast1"
}

variable "zone" {
  default = "asia-northeast1-a"
}

provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

# resource "google_project_services" "project" {
#   project   = "ektp-ocr"
#   services  = [
#     "oslogin.googleapis.com",
#     # "iamcredentials.googleapis.com",
#     # "iam.googleapis.com",
#     # "cloudapis.googleapis.com",
#     # "compute.googleapis.com",
#     # "compute-component.googleapis.com",
#     "serviceusage.googleapis.com",
#     # "storage-api.googleapis.com",
#     # "storage-component.googleapis.com",
#     # "cloudfunctions.googleapis.com", 
#     # "pubsub.googleapis.com"
#   ]
# }

resource "google_pubsub_topic" "ktp" {
  name = "ektp-text-extracted"
}

resource "google_storage_bucket" "uploaded_ektp" {
  name = "ektp"
}

resource "google_storage_bucket" "codes" {
  name = "functions-codes"
}

# HTTP KTP

data "archive_file" "functions-http_ktp" {
  type        = "zip"
  output_path = "${path.module}/dist/http-ktp.zip"
  source_dir  = "./http-ktp"
}

resource "google_storage_bucket_object" "functions-http_ktp" {
  name   = "http-ktp.zip"
  bucket = "${google_storage_bucket.codes.name}"
  source = "${path.module}/dist/http-ktp.zip"
  depends_on = [
    "data.archive_file.functions-http_ktp"
  ]
}

# E-KTP Image Trigger

data "archive_file" "functions-ktp_image_trigger" {
  type        = "zip"
  output_path = "${path.module}/dist/ktp-image-event-trigger.zip"
  source_dir  = "./ktp-image-event-trigger"
}

resource "google_storage_bucket_object" "functions-ktp_image_trigger" {
  name   = "ktp-image-event-trigger.zip"
  bucket = "${google_storage_bucket.codes.name}"
  source = "${path.module}/dist/ktp-image-event-trigger.zip"
  depends_on = ["data.archive_file.functions-http_ktp"]
}

# Extract KTP

data "archive_file" "functions-extract_ktp" {
  type        = "zip"
  output_path = "${path.module}/dist/extract-ktp.zip"
  source_dir  = "./extract-ktp"
}

resource "google_storage_bucket_object" "functions-extract_ktp" {
  name   = "extract-ktp.zip"
  bucket = "${google_storage_bucket.codes.name}"
  source = "${path.module}/dist/extract-ktp.zip"
  depends_on = ["data.archive_file.functions-extract_ktp"]
}

# Cloud functions

resource "google_cloudfunctions_function" "function-http_ktp" {
  name                  = "http-ktp"
  description           = "Function to serve HTTP request for OCR"
  available_memory_mb   = 128
  source_archive_bucket = "${google_storage_bucket.codes.name}"
  source_archive_object = "${google_storage_bucket_object.functions-http_ktp.name}"
  trigger_http          = true
  timeout               = 10
  entry_point           = "uploadKtp"
  depends_on            = ["google_storage_bucket_object.functions-http_ktp"]
}

resource "google_cloudfunctions_function" "function-ktp_image_trigger" {
  name                  = "ktp-image-trigger"
  description           = "Function to storeg image and perform OCR via Google Vision"
  available_memory_mb   = 128
  source_archive_bucket = "${google_storage_bucket.codes.name}"
  source_archive_object = "${google_storage_bucket_object.functions-ktp_image_trigger.name}"
  timeout               = 10
  entry_point           = "processImageFromGCSEvent"
  depends_on            = ["google_storage_bucket_object.functions-ktp_image_trigger"]

  event_trigger {
    event_type = "providers/cloud.storage/eventTypes/object.finalize"
    resource = "uploaded_ektp"
  }
}

resource "google_cloudfunctions_function" "function-extract_ktp" {
  name                  = "extract-ktp"
  description           = "Function to extract data from Google Vision"
  available_memory_mb   = 128
  source_archive_bucket = "${google_storage_bucket.codes.name}"
  source_archive_object = "${google_storage_bucket_object.functions-extract_ktp.name}"
  timeout               = 10
  entry_point           = "extract_ktp"
  runtime               = "python37"
  depends_on            = ["google_storage_bucket_object.functions-extract_ktp"]

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource = "ektp-text-extracted"
  }
}
