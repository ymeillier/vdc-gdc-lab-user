# Data source to reference the parent Terraform state
data "terraform_remote_state" "parent" {
  backend = "local"
  config = {
    path = "../../terraform.tfstate"
  }
}

# Data sources for existing VPC networks
data "google_compute_network" "vdc_vpc1" {
  name    = "vdc-vpc1"
  project = local.gcp_project
}

data "google_compute_network" "vdc_vpc4" {
  name    = "vdc-vpc4"
  project = local.gcp_project
}

# Data sources for existing subnets - we'll reference these dynamically in locals
data "google_compute_subnetwork" "vpc1_subnets" {
  for_each = local.required_vpc1_subnets
  name     = each.value
  region   = local.gcp_region
  project  = local.gcp_project
}

data "google_compute_subnetwork" "vpc4_subnets" {
  for_each = local.required_vpc4_subnets
  name     = each.value
  region   = local.gcp_region
  project  = local.gcp_project
}

# Data source to get the pnetlab server instance information
data "google_compute_instance" "pnetlab_server" {
  name    = data.terraform_remote_state.parent.outputs.pnetlab_server_name
  zone    = local.gcp_zone
  project = local.gcp_project
}

# Data source to get the storage bucket information
# Bucket follows pattern: ${project_id}-bucket-clone
data "google_storage_bucket" "assets_bucket" {
  name = "${local.gcp_project}-bucket-clone"
}

# Note: SSH keys are now downloaded directly by the servers using gsutil
# No need for data sources since the template handles the download directly

# Service Account Key Management
# Check for service account keys from GDC project and read them if they exist
locals {
  # Path to the GDC project's service account keys
  sa_keys_path = "../../gdc-gcp-project/tf/SA-keys"

  # Check if each service account key file exists
  gcr_key_exists       = fileexists("${local.sa_keys_path}/anthos-baremetal-gcr.json")
  connect_key_exists   = fileexists("${local.sa_keys_path}/connect-agent.json")
  register_key_exists  = fileexists("${local.sa_keys_path}/connect-register.json")
  cloud_ops_key_exists = fileexists("${local.sa_keys_path}/anthos-baremetal-cloud-ops.json")
  storage_key_exists   = fileexists("${local.sa_keys_path}/storage-bucket-accessor.json")

  # Read key content if files exist, otherwise set to empty string
  gcr_key_content       = local.gcr_key_exists ? file("${local.sa_keys_path}/anthos-baremetal-gcr.json") : ""
  connect_key_content   = local.connect_key_exists ? file("${local.sa_keys_path}/connect-agent.json") : ""
  register_key_content  = local.register_key_exists ? file("${local.sa_keys_path}/connect-register.json") : ""
  cloud_ops_key_content = local.cloud_ops_key_exists ? file("${local.sa_keys_path}/anthos-baremetal-cloud-ops.json") : ""
  storage_key_content   = local.storage_key_exists ? file("${local.sa_keys_path}/storage-bucket-accessor.json") : ""

  # Message for .nokey files when Workload Identity is used
  workload_identity_message = "No keys were created for the service account to enforce Workload Identity based cluster deployments."
}

# Data sources for scheduling policies from parent terraform state
# These policies are created in the main configuration and shared across all instances
# Only attempt to reference them if auto-shutdown/startup is enabled
data "google_compute_resource_policy" "shutdown_schedule" {
  count  = var.enable_auto_shutdown ? 1 : 0
  name   = "shutdown-2100-america-denver"
  region = local.gcp_region
}

data "google_compute_resource_policy" "startup_schedule" {
  count  = var.enable_auto_startup ? 1 : 0
  name   = "startup-0800-america-denver"
  region = local.gcp_region
}
