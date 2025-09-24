output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.cluster.name
}

output "gke_location" {
  description = "GKE location"
  value       = var.gke_location
}

output "artifact_registry_repo" {
  description = "Artifact Registry repo path"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}
