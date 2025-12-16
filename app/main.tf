provider "google" {
  project = "tp-cloud-gke-nolan"
  region  = "europe-west1"
}

resource "google_container_cluster" "gke" {
  name     = "tp-gke-cluster"
  location = "europe-west1-b"
  initial_node_count = 2
}
