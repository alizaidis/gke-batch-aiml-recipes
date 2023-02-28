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

resource "google_container_cluster" "gke_batch_auto" {
  name                     = "gke-batch-auto"
  project                  = var.project_id
  location                 = var.region
  enable_autopilot         = true
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }
}
