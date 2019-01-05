variable "project" {
  default = "ektp-ocr"
}

variable "region" {
  default = "asia-southeast1"
}

variable "zone" {
  default = "asia-southeast1-a"
}

provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

resource "google_project_services" "project" {
  project   = "ektp-ocr"
  services  = [
    "oslogin.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
    "cloudapis.googleapis.com",
    "compute.googleapis.com",
    "compute-component.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "cloudfunctions.googleapis.com", 
    "pubsub.googleapis.com"
  ]
}

resource "google_pubsub_topic" "ktp" {
  name = "ektp-text-extracted"
  depends_on = ["google_project_services.project"]
}

resource "google_storage_bucket" "functions_store" {
  name = "deploy-ktp-ocr"
  depends_on = ["google_project_services.project"]
}

resource "google_storage_bucket" "ktp" {
  name = "uploaded_ktp"
  depends_on = ["google_project_services.project"]
}

data "archive_file" "functions_http_ktp" {
  type        = "zip"
  output_path = "${path.module}/dist/http-ktp.zip"
  source_dir  = "./http-ktp"
}

# resource "google_storage_bucket_object" "archive" {
#   name   = "http_trigger.zip"
#   bucket = "${google_storage_bucket.codes.name}"
#   source = "${path.module}/files/http_trigger.zip"
#   depends_on = ["data.archive_file.http_trigger"]
# }

# data "archive_file" "http_trigger" {
#   type        = "zip"
#   output_path = "${path.module}/files/http_trigger.zip"
#   source {
#     content  = "${file("${path.module}/files/http_trigger.js")}"
#     filename = "index.js"
#   }
# }


# resource "google_cloudfunctions_function" "function" {
#   name                  = "function-test"
#   description           = "My function"
#   available_memory_mb   = 128
#   source_archive_bucket = "${google_storage_bucket.bucket.name}"
#   source_archive_object = "${google_storage_bucket_object.archive.name}"
#   trigger_http          = true
#   timeout               = 10
#   entry_point           = "helloGET"
#   environment_variables {
#     MY_ENV_VAR = "my-env-var-value"
#   }
# }
