module "enable_google_apis" {
  source     = "terraform-google-modules/project-factory/google//modules/project_services"
  version    = "14.1.0"
  project_id = var.project_id
  activate_apis = [
    "cloudapis.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
  ]
  disable_services_on_destroy = false
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_container_cluster" "gke_batch" {
  name                     = "gke-batch"
  project                  = var.project_id
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = 1
}


resource "google_container_node_pool" "ondemand_np" {
  project    = var.project_id
  name       = "ondemand-np"
  cluster    = resource.google_container_cluster.gke_batch.name
  location   = var.region
  node_config {
    machine_type = "e2-standard-4"
    labels = {
      spot = false
    }
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  autoscaling {
      min_node_count = 1
      max_node_count = 9
      location_policy = "ANY"
  }
  timeouts {
    create = "30m"
    update = "20m"
  }
}

resource "google_container_node_pool" "spot_np" {
  project    = var.project_id
  name       = "spot-np"
  cluster    = resource.google_container_cluster.gke_batch.name
  location   = var.region
  node_config {
    machine_type = "e2-standard-4"
    labels = {
      spot = true
    }
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  autoscaling {
      min_node_count = 0
      max_node_count = 40
      location_policy = "ANY"
  }
  timeouts {
    create = "30m"
    update = "20m"
  }
}

resource "google_container_node_pool" "spot_gpu_np" {
  name       = "spot-gpu-np"
  project    = var.project_id
  cluster    = resource.google_container_cluster.gke_batch.name
  location   = var.region
  node_config {
    machine_type = "a2-highgpu-1g"
    labels = {
      spot = true
    }
    guest_accelerator = [
      {
          type  = "nvidia-tesla-a100"
          count = 1
          gpu_partition_size = "1g.5gb"
          gpu_sharing_config = [
          {   gpu_sharing_strategy = "TIME_SHARING",
              max_shared_clients_per_gpu = 8
          }
        ]
      }
    ]
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  autoscaling {
      min_node_count = 1
      max_node_count = 3
      location_policy = "ANY"
  }
  timeouts {
    create = "30m"
    update = "20m"
  }
}

