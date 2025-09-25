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

# Bucket GCS pour les fichiers NOAA bruts
resource "google_storage_bucket" "raw_weather_bucket" {
  name          = "${var.project_id}-raw-weather"
  location      = "EU"
  force_destroy = true

  uniform_bucket_level_access = true
}

# Dataset BigQuery "raw"
resource "google_bigquery_dataset" "raw_dataset" {
  dataset_id = "raw_data"
  location   = "EU"
}

resource "google_bigquery_table" "raw_weather" {
  dataset_id = google_bigquery_dataset.raw_dataset.dataset_id
  table_id   = "raw_weather"

  deletion_protection = false

  external_data_configuration {
    source_format = "CSV"

    source_uris = [
      "gs://${var.project_id}-raw-weather/raw/*.csv.gz"
    ]

    csv_options {
      skip_leading_rows = 1
      quote             = "\""
    }

    compression = "GZIP"

    autodetect = false  # <-- ajouté pour schema explicite
    schema = jsonencode([
      { "name": "station_id", "type": "STRING", "mode": "REQUIRED" },
      { "name": "observation_date", "type": "DATE", "mode": "REQUIRED" },
      { "name": "temperature", "type": "FLOAT", "mode": "NULLABLE" },
      { "name": "precipitation", "type": "FLOAT", "mode": "NULLABLE" }
    ])
  }
}
