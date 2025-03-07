provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project" "project" {
  name       = var.project_name
  project_id = var.project_id
}

resource "google_firebase_project" "firebase" {
  provider = google-beta
  project  = google_project.project.project_id
}

resource "google_firestore_database" "database" {
  provider                    = google-beta
  project                     = google_project.project.project_id
  name                        = "(default)"
  location_id                 = var.region
  type                        = "FIRESTORE_NATIVE"
  delete_protection_state     = "DELETE_PROTECTION_ENABLED"
  deletion_policy             = "DELETE"
}

resource "google_cloud_run_service" "api" {
  for_each = toset(["main", "staging", "dev"])

  name     = "${var.project_name}-${each.key}"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/api:${each.key}"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_firebase_web_app" "app" {
  provider = google-beta
  project  = google_project.project.project_id
  display_name = var.project_name
}

resource "google_project_service" "services" {
  for_each = toset([
    "firebase.googleapis.com",
    "run.googleapis.com",
    "firestore.googleapis.com",
    "identitytoolkit.googleapis.com"
  ])

  project = google_project.project.project_id
  service = each.key
} 