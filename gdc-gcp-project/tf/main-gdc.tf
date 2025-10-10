# Terraform configuration for creating a new GDC project
# This configuration uses the suffix injected from main.sh and creates a new GDC project


data "terraform_remote_state" "vdc" {
  backend = "local"

  config = {
    path = "${path.module}/../../terraform.tfstate"
  }
}



terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.14.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

# Local variables
locals {
  # Create GDC project ID using the suffix from main.sh
  gdc_project_id = "gdc-${var.suffix}"

  # Use existing VDC project ID to get billing account
  vdc_project_id = "vdc-${var.suffix}"

  # Other local variables
  gcp_orgid    = var.orgid
  gcp_region   = var.gcp_region
  user_account = var.user_account
  svc_account = var.svc_account
}

# Configure the Google Cloud Provider
provider "google" {
  project = local.gdc_project_id
  region  = local.gcp_region
}

# # Get existing VDC project information to extract billing account
# data "google_project" "existing_vdc_project" {
#   project_id = local.vdc_project_id
# }
# 
# # Get billing account information from existing VDC project
# data "google_billing_account" "account" {
#   billing_account = data.google_project.existing_vdc_project.billing_account
# }

# Create project:
resource "google_project" "gdc_project" {
  name            = local.gdc_project_id
  project_id      = local.gdc_project_id
  folder_id       = data.terraform_remote_state.vdc.outputs.gcp_project_folder_id
  billing_account = data.terraform_remote_state.vdc.outputs.billing_account_id
  #folder_id       = data.google_project.existing_vdc_project.folder_id
  #billing_account = data.google_billing_account.account.id

  # labels = {
  #   environment = "gdc"
  #   project_type = "distributed_cloud"
  #   suffix = var.suffix
  # }
}



resource "google_organization_iam_member" "svc_account_policyadmin" {
  org_id = local.gcp_orgid # Your project ID
  role    = "roles/orgpolicy.policyAdmin"
  member  = "serviceAccount:${local.svc_account}"
}




# 1. Data Source to read the Billing Account ID from the local file we exported in main.sh:
data "local_file" "billing_account_id_file" {
  filename = "../../.billing_id"
}

# Note: The billing_user_binding resource has been removed because:
# - The service account already has roles/billing.user granted in main.sh
# - Attempting to grant it again via Terraform requires billing.accounts.setIamPolicy permission
# - This creates a chicken-and-egg problem since the service account doesn't have that permission
# 
# resource "google_billing_account_iam_member" "billing_user_binding" {
#   billing_account_id = trimspace(data.local_file.billing_account_id_file.content)
#   role = "roles/billing.user"
#   member = "serviceAccount:${local.svc_account}"
# }
















# Enable required APIs for GDC project (https://cloud.google.com/kubernetes-engine/distributed-cloud/bare-metal/docs/installing/configure-sa#enable_apis)
# ⚠️ --enable-apis in bmctl: If you will be using the bmctl tool to create clusters, you can include the --enable-apis flag when you run bmctl create config, and bmctl will enable the APIs
resource "google_project_service" "gdc_apis" {
  for_each = toset([
    "anthos.googleapis.com",
    "anthosaudit.googleapis.com",
    "anthosgke.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "connectgateway.googleapis.com",
    "container.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "gkeonprem.googleapis.com",
    "iam.googleapis.com",
    "kubernetesmetadata.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "opsconfigmonitoring.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com"
  ])

  project = google_project.gdc_project.project_id
  service = each.value

  disable_on_destroy = false
}






resource "google_project_service" "project_apis" {
  for_each = toset([
    "orgpolicy.googleapis.com",
  ])

  project = google_project.gdc_project.project_id
  service = each.value

  disable_on_destroy = false
}




















# # Create a storage bucket for GDC project assets
# resource "google_storage_bucket" "gdc_bucket" {
#   name          = "${local.gdc_project_id}-bucket"
#   location      = local.gcp_region
#   project       = google_project.gdc_project.project_id
#   force_destroy = false
#   
#   uniform_bucket_level_access = true
#   
#   labels = {
#     environment = "gdc"
#     project = local.gdc_project_id
#   }
#   
#   depends_on = [google_project_service.gdc_apis]
# }
























# Grant user necessary permissions on the GDC project (https://cloud.google.com/kubernetes-engine/distributed-cloud/bare-metal/docs/installing/configure-sa#before_you_begin)
# Updated with additional WICA roles
resource "google_project_iam_member" "user_permissions" {
  for_each = toset([
    "roles/compute.viewer",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.securityAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/gkeonprem.admin",
    "roles/gkehub.viewer",
    "roles/container.viewer",
    "roles/owner",
    "roles/compute.admin",
    "roles/storage.admin",
    # Additional WICA roles
    "roles/gkehub.admin",
    "roles/logging.admin",
    "roles/monitoring.admin",
    "roles/monitoring.dashboardEditor",
    "roles/iam.serviceAccountTokenCreator"
  ])

  project = google_project.gdc_project.project_id
  role    = each.value
  member  = "user:${local.user_account}"
}

# Grant the Terraform service account necessary permissions for policy validation
# This allows the service account to create test service accounts for the policy validation script
resource "google_project_iam_member" "terraform_svc_account_permissions" {
  for_each = toset([
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountKeyAdmin"
  ])

  project = google_project.gdc_project.project_id
  role    = each.value
  member  = "serviceAccount:${local.svc_account}"
}

# # Output important information
# output "gdc_project_id" {
#   description = "The ID of the created GDC project"
#   value       = google_project.gdc_project.project_id
# }
# output "gdc_project_number" {
#   description = "The number of the created GDC project"
#   value       = google_project.gdc_project.number
# }
# output "vdc_folder_id" {
#   description = "The ID of the VDC folder (shared with GDC project)"
#   value       = data.google_project.existing_vdc_project.folder_id
# }
# output "used_suffix" {
#   description = "The suffix used for the GDC project"
#   value       = var.suffix
# }
# 
# output "gdc_bucket_name" {
#   description = "The name of the created GDC storage bucket"
#   value       = google_storage_bucket.gdc_bucket.name
# }

# output "billing_account_id" {
#   description = "The billing account ID used for the GDC project"
#   value       = data.google_billing_account.account.id
# }
























# Organizational Policy: Allow service account key creation
# This overrides the organization-level constraint that blocks service account key creation
resource "google_org_policy_policy" "iam_disableServiceAccountKeyCreation" {
  name   = "projects/${local.gdc_project_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "projects/${local.gdc_project_id}"
  spec {
    rules {
      enforce = "FALSE"
    }
  }
  depends_on = [google_project_service.project_apis]
}

# External validation to ensure the organizational policy is actually active
# This tests policy enforcement by attempting to create a test service account key
data "external" "policy_validation" {
  program = ["bash", "${path.module}/scripts/validate_policy_active.sh"]
  
  query = {
    project_id = local.gdc_project_id
  }
  
  depends_on = [
    google_org_policy_policy.iam_disableServiceAccountKeyCreation,
    google_project_iam_member.terraform_svc_account_permissions
  ]
}










# Custom IAM role for storage bucket accessor
resource "google_project_iam_custom_role" "storage_bucket_accessor" {
  role_id     = "storageBucketAccessor"
  title       = "Storage Bucket Accessor"
  description = "Custom role for Anthos Bare Metal storage bucket access"
  project     = google_project.gdc_project.project_id

  permissions = [
    "storage.buckets.create",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "resourcemanager.projects.get"
  ]

  depends_on = [google_project_service.gdc_apis]
}














# Service Accounts: (https://cloud.google.com/kubernetes-engine/distributed-cloud/bare-metal/docs/installing/configure-sa#configuring-sa)
# ⚠️ --create-service-accounts: If you will be using the bmctl tool to create clusters, you can include the --create-service-accounts flag when you run bmctl create config to have bmctl create the service accounts with the required IAM roles.



## Service Accounts: Anthos Bare Metal Service Accounts
resource "google_service_account" "anthos_baremetal_gcr" {
  account_id   = "anthos-baremetal-gcr"
  display_name = "Anthos Bare Metal GCR Service Account"
  description  = "Service account for Anthos Bare Metal GCR access. Google Distributed Cloud uses this service account to download container images from Artifact Registry."
  project      = google_project.gdc_project.project_id

  depends_on = [google_project_service.gdc_apis]
}

resource "google_service_account" "anthos_baremetal_connect" {
  account_id   = "anthos-baremetal-connect"
  display_name = "Anthos Bare Metal Connect Service Account"
  description  = "Service account for Anthos Bare Metal cluster connection and workload management features."
  project      = google_project.gdc_project.project_id

  depends_on = [google_project_service.gdc_apis]
}

resource "google_service_account" "anthos_baremetal_register" {
  account_id   = "anthos-baremetal-register"
  display_name = "Anthos Bare Metal Register Service Account"
  description  = "Service account for Anthos Bare Metal cluster registration"
  project      = google_project.gdc_project.project_id

  depends_on = [google_project_service.gdc_apis]
}

resource "google_service_account" "anthos_baremetal_cloud_ops" {
  account_id   = "anthos-baremetal-cloud-ops"
  display_name = "Anthos Bare Metal Cloud Ops Service Account"
  description  = "Service account for Anthos Bare Metal cloud operations.Stackdriver Agent uses this service account to export logs and metrics from clusters to Cloud Logging and Cloud Monitoring."
  project      = google_project.gdc_project.project_id

  depends_on = [google_project_service.gdc_apis]
}

resource "google_service_account" "storage_bucket_accessor" {
  account_id   = "storage-bucket-accessor"
  display_name = "Storage Bucket Accessor Service Account"
  description  = "Service account for storage bucket access, cluster snapshots, and VM image imports for GDC."
  project      = google_project.gdc_project.project_id

  depends_on = [google_project_service.gdc_apis]
}

## Service Accounts: Workload Identity Service Accounts (https://cloud.google.com/kubernetes-engine/distributed-cloud/bare-metal/docs/installing/wi-cluster-auth#before_you_begin)




































# IAM role bindings for service accounts

# anthos-baremetal-connect: roles/gkehub.connect
resource "google_project_iam_member" "anthos_baremetal_connect_role" {
  project = google_project.gdc_project.project_id
  role    = "roles/gkehub.connect"
  member  = "serviceAccount:${google_service_account.anthos_baremetal_connect.email}"
}

# anthos-baremetal-register: roles/gkehub.admin
resource "google_project_iam_member" "anthos_baremetal_register_role" {
  project = google_project.gdc_project.project_id
  role    = "roles/gkehub.admin"
  member  = "serviceAccount:${google_service_account.anthos_baremetal_register.email}"
}

# anthos-baremetal-cloud-ops: multiple roles
resource "google_project_iam_member" "anthos_baremetal_cloud_ops_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/opsconfigmonitoring.resourceMetadata.writer",
    "roles/monitoring.dashboardEditor",
    "roles/monitoring.viewer",
    "roles/serviceusage.serviceUsageViewer",
    "roles/kubernetesmetadata.publisher"
  ])

  project = google_project.gdc_project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.anthos_baremetal_cloud_ops.email}"
}

# storage-bucket-accessor: custom role
resource "google_project_iam_member" "storage_bucket_accessor_role" {
  project = google_project.gdc_project.project_id
  role    = google_project_iam_custom_role.storage_bucket_accessor.id
  member  = "serviceAccount:${google_service_account.storage_bucket_accessor.email}"
}

# Outputs for service account information
output "anthos_service_accounts" {
  description = "Anthos Bare Metal service account emails"
  value = {
    gcr       = google_service_account.anthos_baremetal_gcr.email
    connect   = google_service_account.anthos_baremetal_connect.email
    register  = google_service_account.anthos_baremetal_register.email
    cloud_ops = google_service_account.anthos_baremetal_cloud_ops.email
    storage   = google_service_account.storage_bucket_accessor.email
  }
}

output "custom_role_id" {
  description = "Custom storage bucket accessor role ID"
  value       = google_project_iam_custom_role.storage_bucket_accessor.id
}

# Output for policy validation status
output "policy_validation_status" {
  description = "Status of the organizational policy validation"
  value = {
    status  = data.external.policy_validation.result.status
    message = data.external.policy_validation.result.message
  }
}

# Option 1/ Downloads key (https://cloud.google.com/kubernetes-engine/distributed-cloud/bare-metal/docs/installing/configure-sa#configure_service_accounts_manually)

# Service Account Keys - Create keys for all Anthos Bare Metal service accounts
# These depend on external validation confirming the policy is actually enforced
resource "google_service_account_key" "anthos_baremetal_gcr_key" {
  service_account_id = google_service_account.anthos_baremetal_gcr.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  
  depends_on = [data.external.policy_validation]
}

resource "google_service_account_key" "anthos_baremetal_connect_key" {
  service_account_id = google_service_account.anthos_baremetal_connect.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  
  depends_on = [data.external.policy_validation]
}

resource "google_service_account_key" "anthos_baremetal_register_key" {
  service_account_id = google_service_account.anthos_baremetal_register.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  
  depends_on = [data.external.policy_validation]
}

resource "google_service_account_key" "anthos_baremetal_cloud_ops_key" {
  service_account_id = google_service_account.anthos_baremetal_cloud_ops.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  
  depends_on = [data.external.policy_validation]
}

resource "google_service_account_key" "storage_bucket_accessor_key" {
  service_account_id = google_service_account.storage_bucket_accessor.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  
  depends_on = [data.external.policy_validation]
}

# Download service account keys to SA-keys folder
# Note: Add SA-keys/ to .gitignore to prevent committing sensitive keys
resource "local_file" "anthos_baremetal_gcr_json" {
  content         = base64decode(google_service_account_key.anthos_baremetal_gcr_key.private_key)
  filename        = "${path.module}/SA-keys/anthos-baremetal-gcr.json"
  file_permission = "0600"
}

resource "local_file" "connect_agent_json" {
  content         = base64decode(google_service_account_key.anthos_baremetal_connect_key.private_key)
  filename        = "${path.module}/SA-keys/connect-agent.json"
  file_permission = "0600"
}

resource "local_file" "connect_register_json" {
  content         = base64decode(google_service_account_key.anthos_baremetal_register_key.private_key)
  filename        = "${path.module}/SA-keys/connect-register.json"
  file_permission = "0600"
}

resource "local_file" "anthos_baremetal_cloud_ops_json" {
  content         = base64decode(google_service_account_key.anthos_baremetal_cloud_ops_key.private_key)
  filename        = "${path.module}/SA-keys/anthos-baremetal-cloud-ops.json"
  file_permission = "0600"
}

resource "local_file" "storage_bucket_accessor_json" {
  content         = base64decode(google_service_account_key.storage_bucket_accessor_key.private_key)
  filename        = "${path.module}/SA-keys/storage-bucket-accessor.json"
  file_permission = "0600"
}

# Outputs for service account key file paths
output "service_account_key_files" {
  description = "Paths to downloaded service account key files"
  value = {
    anthos_baremetal_gcr       = local_file.anthos_baremetal_gcr_json.filename
    connect_agent              = local_file.connect_agent_json.filename
    connect_register           = local_file.connect_register_json.filename
    anthos_baremetal_cloud_ops = local_file.anthos_baremetal_cloud_ops_json.filename
    storage_bucket_accessor    = local_file.storage_bucket_accessor_json.filename
  }
}

# Option 2/ Workload Identity based Cluster Authentication (https://cloud.google.com/kubernetes-engine/distributed-cloud/bare-metal/docs/installing/wi-cluster-auth)

## Service Accounts for GDC Workload Identity based cluster authentication

# baremetal-controller service account
resource "google_service_account" "baremetal_controller" {
  account_id   = "baremetal-controller"
  display_name = "Baremetal Controller Service Account"
  description  = "Connect Agent service account for cluster connection, fleet registration, and token refresh."
  project      = google_project.gdc_project.project_id

  depends_on = [google_project_service.gdc_apis]
}

# baremetal-cloud-ops service account
resource "google_service_account" "baremetal_cloud_ops" {
  account_id   = "baremetal-cloud-ops"
  display_name = "Baremetal Cloud Ops Service Account"
  description  = "Stackdriver Agent uses this service account to export logs and metrics from clusters to Cloud Logging and Cloud Monitoring."
  project      = google_project.gdc_project.project_id

  depends_on = [google_project_service.gdc_apis]
}

# baremetal-gcr service account
resource "google_service_account" "baremetal_gcr" {
  account_id   = "baremetal-gcr"
  display_name = "Baremetal GCR Service Account"
  description  = "Google Distributed Cloud uses this service account to download container images from Artifact Registry."
  project      = google_project.gdc_project.project_id

  depends_on = [google_project_service.gdc_apis]
}

## IAM role bindings for GDC WICA service accounts

# baremetal-controller: required roles
resource "google_project_iam_member" "baremetal_controller_roles" {
  for_each = toset([
    "roles/gkehub.admin",
    "roles/monitoring.dashboardEditor",
    "roles/serviceusage.serviceUsageViewer"
  ])

  project = google_project.gdc_project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.baremetal_controller.email}"
}

# baremetal-cloud-ops: required roles
resource "google_project_iam_member" "baremetal_cloud_ops_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/opsconfigmonitoring.resourceMetadata.writer",
    "roles/monitoring.dashboardEditor",
    "roles/monitoring.viewer",
    "roles/serviceusage.serviceUsageViewer",
    "roles/kubernetesmetadata.publisher"
  ])

  project = google_project.gdc_project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.baremetal_cloud_ops.email}"
}

# baremetal-gcr: no roles required (as specified in requirements)

## Outputs for GDC WICA service accounts
output "gdc_wica_service_accounts" {
  description = "GDC Workload Identity based cluster authentication service account emails"
  value = {
    baremetal_controller = google_service_account.baremetal_controller.email
    baremetal_cloud_ops  = google_service_account.baremetal_cloud_ops.email
    baremetal_gcr        = google_service_account.baremetal_gcr.email
  }
}
