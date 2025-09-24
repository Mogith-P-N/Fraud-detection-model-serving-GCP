variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gke_location" {
  description = "GKE location (region or zone)"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "fraud-gke"
}

variable "artifact_repo_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "fraud-models"
}

variable "github_repo" {
  description = "GitHub repo in org/name format for OIDC trust"
  type        = string
}
