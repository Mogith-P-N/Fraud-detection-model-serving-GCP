resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
  ])
  project = var.project_id
  service = each.key
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.artifact_repo_name
  description   = "Container images for fraud prediction service"
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes"
  display_name = "GKE Nodes Service Account"
}

resource "google_container_cluster" "cluster" {
  name     = var.cluster_name
  location = var.gke_location

  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  depends_on = [google_project_service.apis]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary"
  location   = var.gke_location
  cluster    = google_container_cluster.cluster.name
  node_count = 2

  node_config {
    service_account = google_service_account.gke_nodes.email
    machine_type    = "e2-standard-2"
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    labels = {
      env = "prod"
    }
    tags = ["fraud-gke"]
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 10
  }
}

# Workload Identity Federation for GitHub Actions
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions OIDC Pool"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions"
  attribute_mapping = {
    "google.subject"           = "assertion.sub"
    "attribute.repository"     = "assertion.repository"
    "attribute.ref"            = "assertion.ref"
    "attribute.actor"          = "assertion.actor"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service account for CI to push to Artifact Registry and deploy to GKE
resource "google_service_account" "ci" {
  account_id   = "github-actions-ci"
  display_name = "GitHub Actions CI"
}

resource "google_service_account_iam_member" "ci_wi_user" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

resource "google_project_iam_member" "ci_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/container.developer",
    "roles/container.admin",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.ci.email}"
}
