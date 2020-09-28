# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.app_name}-${var.env}-vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}

resource "google_compute_router" "vpc_router" {
  name = "${var.app_name}-${var.env}-vpc-router"

  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.self_link
}

## SUBNETS
# Creating 1 public and 1 private, leaving plenty of address space for additional subnets in the future
# Provisioning ~ 8k / 65k possible for this VPC's address space of 10.x.0.0/16

# Public Subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.app_name}-${var.env}-public-subnet"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.self_link
  # 10.x.0.1 - 10.x.15.254
  # ~4k hosts
  ip_cidr_range = "10.${var.vpc_block_primary}.0.0/20"
  # 10.x+1.0.1 - 10.x+1.15.254
  # ~4k containers/aliases
  secondary_ip_range {
    range_name = "public-secondary"
    ip_cidr_range = "10.${var.vpc_block_secondary}.0.0/20"
  }
}

# Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.app_name}-${var.env}-private-subnet"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.self_link
  # 10.x.16.1 - 10.x.31.254
  # ~4k hosts
  ip_cidr_range = "10.${var.vpc_block_primary}.16.0/20"
  # 10.x+1.16.1 - 10.x+1.31.254
  # ~4k containers/aliases
  secondary_ip_range {
    range_name = "private-secondary"
    ip_cidr_range = "10.${var.vpc_block_secondary}.16.0/20"
  }
}

# NAT Gateway for Private subnet
resource "google_compute_router_nat" "vpc_nat" {
  name = "${var.app_name}-${var.env}-nat"

  project = var.project_id
  region  = var.region
  router  = google_compute_router.vpc_router.name

  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

locals {
  private_tag = "private"
  public_tag = "public"
}

resource "google_compute_firewall" "public_firewall_inbound" {

  name = "${var.app_name}-${var.env}-public-allow-ingress"

  project = var.project_id
  network = google_compute_network.vpc.self_link

  target_tags   = ["public"]
  direction     = "INGRESS"

  # For this project lets lock this to my IP only
  source_ranges = [
    var.my_public_ip
  ]

  priority = "1000"

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "private_inbound" {
  name = "${var.app_name}-${var.env}-private-allow-ingress"

  project = var.project_id
  network = google_compute_network.vpc.self_link

  target_tags = ["private"]
  direction   = "INGRESS"

  # Allow all within VPC
  source_ranges = [
    google_compute_subnetwork.public_subnet.ip_cidr_range,
    google_compute_subnetwork.public_subnet.secondary_ip_range[0].ip_cidr_range,
    google_compute_subnetwork.private_subnet.ip_cidr_range,
    google_compute_subnetwork.private_subnet.secondary_ip_range[0].ip_cidr_range,
  ]

  priority = "1000"

  allow {
    protocol = "all"
  }
}

