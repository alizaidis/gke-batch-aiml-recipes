# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Reservation to be consumed in GKE cluster

resource "google_compute_reservation" "zonal_reservation" {
  project = var.project_id
  specific_reservation_required = true
  name = "${var.zone}-reservation"
  zone = var.zone

  specific_reservation {
    count = var.reservation_count
    instance_properties {
      min_cpu_platform = "Intel Cascade Lake"
      machine_type     = "n2-standard-4"
    }
  }
}


# google_client_config and kubernetes provider must be explicitly specified like the following for every cluster.

## GKE cluster

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${resource.google_container_cluster.gke_batch.endpoint}"
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


resource "google_container_node_pool" "reserved_np" {
  project    = var.project_id
  name       = "reserved-np"
  cluster    = resource.google_container_cluster.gke_batch.name
  node_count = var.reservation_count
  node_locations = ["${var.zone}"]
  location   = var.region
  node_config {
    machine_type = "n2-standard-4"
    reservation_affinity {
      consume_reservation_type = "SPECIFIC_RESERVATION"
      key = "compute.googleapis.com/reservation-name"
      values = ["${var.zone}-reservation"]
    }
    labels = {
      spot = false
    }
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  timeouts {
    create = "30m"
    update = "20m"
  }
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
      min_node_count = 0
      max_node_count = 5
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
      min_node_count = 0
      max_node_count = 3
      location_policy = "ANY"
  }
  timeouts {
    create = "30m"
    update = "20m"
  }
}