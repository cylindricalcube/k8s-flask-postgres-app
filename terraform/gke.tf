
# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE REGIONAL PUBLIC CLUSTER IN GOOGLE CLOUD
# ---------------------------------------------------------------------------------------------------------------------

module "gke_cluster" {
  source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-cluster?ref=v0.5.0"

  name = "${var.app_name}-${var.env}-cluster"

  project  = var.project_id
  location = var.region

  network = google_compute_network.vpc.self_link

  subnetwork                   = google_compute_subnetwork.public_subnet.name
  cluster_secondary_range_name = google_compute_subnetwork.public_subnet.secondary_ip_range[0].range_name

  kubernetes_version = "1.17"
  # Let's turn off autoscaling for our purposes
  horizontal_pod_autoscaling = "false"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NODE POOL
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_node_pool" "node_pool" {

  name     = "${var.app_name}-${var.env}-cluster-main-pool"
  project  = var.project_id
  location = var.region
  cluster  = module.gke_cluster.name

  initial_node_count = "1"

  autoscaling {
    min_node_count = "1"
    max_node_count = "1"
  }

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    image_type   = "COS"
    machine_type = "n1-standard-1"

    # This tag sets the public firewall association
    tags = [
      "public",
    ]

    disk_size_gb = "10"
    disk_type    = "pd-standard"
    preemptible  = false

    service_account = module.gke_service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A CUSTOM SERVICE ACCOUNT TO USE WITH THE GKE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "gke_service_account" {
  source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-service-account?ref=v0.3.9"

  name        = "${var.app_name}-${var.env}-cluster"
  project     = var.project_id
}

