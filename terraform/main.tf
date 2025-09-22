terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    bucket  = "prime-hour-472917-d3-tfstate-bucket"
    prefix  = "terraform/state"  # chemin interne pour le fichier tfstate
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "europe-west1"
}

# Bucket GCS pour stocker les fichiers
resource "google_storage_bucket" "data_bucket" {
  name          = "${var.project_id}-data-bucket"
  location      = "EU"
  force_destroy = true
}

# Dataset BigQuery "raw"
resource "google_bigquery_dataset" "raw_dataset" {
  dataset_id = "raw_data"
  location   = "EU"
}
