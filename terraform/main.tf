####################
# PROVIDERS
####################

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  load_config_file = false

  host                   = data.template_file.gke_host_endpoint.rendered
  token                  = data.template_file.access_token.rendered
  cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
}

# We use this data provider to expose an access token for communicating with the GKE cluster.
data "google_client_config" "client" {}

# Use this datasource to access the Terraform account's email for Kubernetes permissions.
data "google_client_openid_userinfo" "terraform_user" {}

# This is a workaround for the Kubernetes and Helm providers as Terraform doesn't currently support passing in module
# outputs to providers directly.
data "template_file" "gke_host_endpoint" {
  template = module.gke_cluster.endpoint
}

data "template_file" "access_token" {
  template = data.google_client_config.client.access_token
}

data "template_file" "cluster_ca_certificate" {
  template = module.gke_cluster.cluster_ca_certificate
}

####################
# TF SETUP
####################

terraform {
  required_version = ">= 0.12"
}
