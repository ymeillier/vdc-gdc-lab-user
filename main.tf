## Cloned from gitlab. git@gitlab.com/ymeillier/vDC-tf.git


#### CHANGES TO IMPLEMENT:
## USE random number as suffix for 
##  Project ID
##  vdc-tf-clone-<> bucket



## 01-Setup (legacy manual setups. Before the implementation of main.sh)
#
# terraform version shows cloud shell version is outdated.
# admin_@cloudshell:~/GDCv/GDCv-tf$ terraform version
#   Terraform v1.5.7
#   on linux_amd64
#   Your version of Terraform is out of date! The latest version
#   is 1.10.2. You can update by downloading from https://www.terraform.io/downloads.html
#
# wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
# sudo apt update && sudo apt install terraform
#
# admin_@cloudshell:~/GDCv/GDCv-tf$ terraform version
#   Terraform v1.10.3
#   on linux_amd64
#
# cat >> ~/.bashrc << EOF
# alias tf="terraform"
# EOF
#
# source ~/.bashrc
#
# admin_@cs-173025914001-default:~/GDCv/vDC-tf$ gcloud projects list | grep -E 'vdc-tf2'
#   vdc-tf2                         vdc-tf2              250796033514
#
# Terraform Google provider:
#   https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gkeonprem_bare_metal_admin_cluster
#
#
#
#
# terraform init




terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.14.1"
    }
    # random = { # Add the random provider
    #   source  = "hashicorp/random"
    #   version = "~> 3.0" # Or a compatible version constraint
    # }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0" # Or the latest version compatible with your Terraform version
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0" # Or the latest version
    }
    external = {
      source  = "registry.terraform.io/hashicorp/external"
      version = ">= 2.0.0" # Replace with the desired version constraint
    }
  }
}

provider "google" {
  # Configuration options
  project = local.gcp-project
  region  = local.gcp-region
  user_project_override = true
  billing_project       = var.gcp_project
}

## Manual step pre-implementation of main.sh
# resource "null_resource" "set_gcloud_project" {
#   provisioner "local-exec" {
#     command = "gcloud config set project ${local.gcp-project}"
#   }
# }
#
# resource "random_integer" "project_suffix" {
#   min = 100000 # Minimum 6-digit number
#   max = 999999 # Maximum 6-digit number
# }




# Local variables are now defined in locals.tf to include billing account file reading logic



































##02-Enable-APIs


# Enable APIs
resource "google_project_service" "cloudresourcemanager_googleapis_com" {
  project            = local.gcp-project
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false # Set to true to disable on destroy
}
# resource "google_project_service" "compute_googleapis_com" {
#   project            = local.gcp-project
#   service            = "compute.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }

resource "google_project_service" "serviceusage_googleapis_com" {
  project            = local.gcp-project
  service            = "serviceusage.googleapis.com"
  disable_on_destroy = false # Set to true to disable on destroy
}

resource "google_project_service" "orgpolicy_googleapis_com" {
  project            = local.gcp-project
  service            = "orgpolicy.googleapis.com"
  disable_on_destroy = false # Set to true to disable on destroy
}

# resource "google_project_service" "iap_api" {
#   service            = "iap.googleapis.com"
#   disable_on_destroy = false # Important: Prevents accidental disabling
# }

# resource "google_project_service" "storage_api" {
#   project            = local.gcp-project
#   service            = "storage.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }

resource "google_project_service" "cloudbuild_api" {
  project            = local.gcp-project
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false # Set to true to disable on destroy
}
# [ypm: somehow going to the console teh cloud build api still had to be enabled.... ]











































##03-IAM-Roles-Permissions

# IAM Roles and Permissions

# resource "local_file" "sas-file" {
#   filename = "SAs.txt"
#   content  = "${local.cloudbuild-sa}\n${local.gce-sa}"
# }


# Permissions needed by cloudbuild SA for the gcloud images export command:

resource "google_project_iam_member" "compute_admin_cloudbuild_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/compute.admin"
  member  = "serviceAccount:${local.cloudbuild-sa}"
  depends_on = [google_project_service.cloudbuild_api]
}

resource "google_project_iam_member" "storage_admin_cloudbuild_sa" {
  project = local.gcp-project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${local.cloudbuild-sa}"
  depends_on = [google_project_service.cloudbuild_api]
}

resource "google_project_iam_member" "service_account_user_cloudbuild_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.cloudbuild-sa}"
  depends_on = [google_project_service.cloudbuild_api]
}

resource "google_project_iam_member" "service_account_token_creator_cloudbuild_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${local.cloudbuild-sa}"
  depends_on = [google_project_service.cloudbuild_api]
}

resource "google_project_iam_member" "service_account_net_user_cloudbuild_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${local.cloudbuild-sa}"
  depends_on = [google_project_service.cloudbuild_api]
}

resource "google_project_iam_member" "service_account_builder_cloudbuild_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${local.cloudbuild-sa}"
  depends_on = [google_project_service.cloudbuild_api]
}

# assign to gce-sa in case use that instead of cloudbuild sa when exporting image (console does that)
resource "google_project_iam_member" "compute_admin_gce_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/compute.admin"
  member  = "serviceAccount:${local.gce-sa}"
}

resource "google_project_iam_member" "service_account_token_creator_gce_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${local.gce-sa}"
}

resource "google_project_iam_member" "service_account_user_gce_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.gce-sa}"
}

resource "google_project_iam_member" "service_account_net_user_gce_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${local.gce-sa}"
}

resource "google_project_iam_member" "service_account_builder_gce_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${local.gce-sa}"
}

# Permissions needed by the default gce SA for the gcloud images export command:
# https://cloud.google.com/compute/docs/import/requirements-export-import-images#required-roles-compute-sa

resource "google_project_iam_member" "compute_storage_admin_gce_sa" {
  project = local.gcp-project
  role    = "roles/compute.storageAdmin"
  member  = "serviceAccount:${local.gce-sa}"
}

resource "google_project_iam_member" "storage_object_admin_gce_sa" {
  project = local.gcp-project
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${local.gce-sa}"
}

resource "google_project_iam_member" "storage_admin_gce_sa" {
  project = local.gcp-project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${local.gce-sa}"
}


resource "google_project_iam_member" "storage_object_viewer_gce_sa" {
  project = local.gcp-project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${local.gce-sa}"
}

# Grant the automation SA permission to attach the GCE SA to instances
# This is required when terraform-automation-sa creates VMs with local.gce-sa attached
resource "google_project_iam_member" "automation_sa_can_use_gce_sa" {
  project = local.gcp-project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.svc-account}"
}



# User permission per https://cloud.google.com/compute/docs/import/requirements-export-import-images#grant-user-account-role

resource "google_project_iam_member" "storage_admin_user" {
  project = local.gcp-project
  role    = "roles/storage.admin"
  member  = "user:${local.user-account}"
}

resource "google_project_iam_member" "viewer_gce_user" {
  project = local.gcp-project
  role    = "roles/viewer"
  member  = "user:${local.user-account}"
}

resource "google_project_iam_member" "projectiamadmin_user" {
  project = local.gcp-project
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "user:${local.user-account}"
}

resource "google_project_iam_member" "cloudbuildeditor_user" {
  project = local.gcp-project
  role    = "roles/cloudbuild.builds.editor"
  member  = "user:${local.user-account}"
}







































# ## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project

# # resource "google_project" "project" {
# #   auto_create_network = true
# #   name                = local.gcp-project
# #   org_id              = local.gcp-orgid
# #   project_id          = local.gcp-project
# # }

# # data "google_project" "project_data" {
# #   project_id = google_project.project.project_id
# #   depends_on = [google_project.project] # Crucial: Ensures project exists first
# # }

# # output "project_number" {
# #   value = data.google_project.project_data.number
# # }

# # output "project_id_output" {
# #   value = data.google_project.project_data.id
# # }






















































##04-ORG-Policies




# # org policy: compute.requireShieldedVm
resource "google_org_policy_policy" "compute_requireShieldedVm" {
  name   = "projects/${local.gcp-project}/policies/compute.requireShieldedVm"
  parent = "projects/${local.gcp-project}"
  spec {
    rules {
      enforce = "FALSE"
    }
  }
  depends_on = [google_project_service.orgpolicy_googleapis_com]
}

  ## Troubleshooting:
  ##   depends_on = [google_project_service.orgpolicy_googleapis_com]
  ## terraform apply -target=google_org_policy_policy.compute_requireShieldedVm
  ## terraform destroy -target=google_org_policy_policy.compute_requireShieldedVm
  ## terraform import google_org_policy_policy.compute_requireShieldedVm projects/${local.gcp-project}/policies/compute.requireShieldedVm
  ## gcloud org-policies list --project $PROJECT 
  ## gcloud org-policies list --folder $FOLDER_ID

# # org policy: vmCanIpForward
resource "google_org_policy_policy" "compute_vmCanIpForward" {
  name   = "projects/${local.gcp-project}/policies/compute.vmCanIpForward"
  parent = "projects/${local.gcp-project}"
  spec {
    rules {
      allow_all = "TRUE"
    }
  }
  depends_on = [google_project_service.orgpolicy_googleapis_com]
}



resource "google_org_policy_policy" "compute_vmExternalIpAccess" {
  name   = "projects/${local.gcp-project}/policies/compute.vmExternalIpAccess"
  parent = "projects/${local.gcp-project}"
  spec {
    rules {
      allow_all = "TRUE"
    }
  }
  depends_on = [google_project_service.orgpolicy_googleapis_com]
}


# ## org policy: disableSerialPortAccess
resource "google_org_policy_policy" "compute_disableSerialPortAccess" {
  name   = "projects/${local.gcp-project}/policies/compute.disableSerialPortAccess"
  parent = "projects/${local.gcp-project}"
  
  spec {
    rules {
      enforce = "FALSE"
    }
  }
  depends_on = [google_project_service.orgpolicy_googleapis_com]
}



# ## org policy: requireOsLogin
resource "google_org_policy_policy" "compute_requireOsLogin" {
  name   = "projects/${local.gcp-project}/policies/compute.requireOsLogin"
  parent = "projects/${local.gcp-project}"
  spec {
    rules {
      enforce = "FALSE"
    }
  }
  depends_on = [google_project_service.orgpolicy_googleapis_com]
}




# ## org policy: disableNestedVirtualization
resource "google_org_policy_policy" "compute_disableNestedVirtualization" {
  name   = "projects/${local.gcp-project}/policies/compute.disableNestedVirtualization"
  parent = "projects/${local.gcp-project}"
  spec {
    rules {
      enforce = "FALSE"
    }
  }
  depends_on = [google_project_service.orgpolicy_googleapis_com]
}


resource "google_org_policy_policy" "allow_compute_image_import" {
  name   = "projects/${local.gcp-project}/policies/compute.trustedImageProjects"
  parent = "projects/${local.gcp-project}"

  spec {
    rules {
      values {
        allowed_values = [
          "projects/debian-cloud",
          "projects/ubuntu-os-pro-cloud",
          "projects/cos-cloud",
          "projects/windows-cloud",
          "projects/compute-image-import"
        ]
      }
    }
  }
  depends_on = [google_project_service.orgpolicy_googleapis_com]
}

# # Data source to validate that compute policies have propagated
# data "external" "validate_compute_policies" {
#   program = ["bash", "${path.module}/scripts/validate_compute_policies.sh"]
# 
#   query = {
#     project_id = local.gcp-project
#     gcp_zone   = local.gcp-zone
#   }
# 
#   depends_on = [
#     google_org_policy_policy.compute_requireShieldedVm,
#     google_org_policy_policy.compute_vmCanIpForward,
#     google_org_policy_policy.compute_vmExternalIpAccess,
#     google_org_policy_policy.compute_disableSerialPortAccess,
#     google_org_policy_policy.compute_requireOsLogin,
#     google_org_policy_policy.compute_disableNestedVirtualization,
#     google_org_policy_policy.allow_compute_image_import,
#   ]
# }






























































##05-VPC-Networks


# VPC Networks

# Main subnet will be 10.10.10.0/24 - pnet server mgmt ip will be on that subnet.
# Each servers deployed on the service rack, border rack, rack 1, 2, 3, 4 have a mgmt IP in VPC1. 
# However in order to differentiate servers ips by rack location, we use the same ip addressing convention
# used for VTEP/underlay networks
# A server on rack 1 vlan 101 (101-109 allowed only) will have a mgmt ip on 10.10.1XL.IP where X is the rack id and L the vlan id so:
# - 10.10.115.10 would be a server on rack 1 vlan 105. 
# - 10.10.123.10 would be a server on rack 2 vlan 103. 
# - 10.10.123.10 would be a server on rack 2 vlan 103. 
# - 10.10.103.10 would be a server on rack 0 (border) vlan 103. 
# - 10.10.94.10 would be a server on rack 99 (service rack) vlan 104. 
# Because the vlan ID is a single digit in that convention, we can only have 9 vlans (I guess could have added 0 for the 0th vlan but script would need to accomodate that)
# an improvement would be to use 
# 10.1.122.x for rack 1 vlan 122. 
# 10.99.122.x for rack 99 (svc) vlan 122. 
# 10.22.122.x for rack 22 vlan 122. 
# The idea though was to preserver the 10/8 address space to VPC infra address and avoid potential conflicts across VPC (if was peering)
# With this addressing schema we know that 10.10/16 and 10.40/16 is reserved



# Default vpc network: Required by gcloud compute images export: in console, doing the export, failed because of lack of global 'Default' network
# [image-export]: 2025-01-06T16:15:04Z Validation of network "projects/vdc-tf/global/networks/default" failed: googleapi: Error 404: The resource 'projects/vdc-tf/global/networks/default' was not found, notFound
resource "google_compute_network" "vdc_default" {
  auto_create_subnetworks                   = true
  mtu                                       = 8896
  name                                      = "default"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.gcp-project
  routing_mode                              = "GLOBAL"

  #depends_on = [google_project_service.compute_googleapis_com]
}


# vpc1: Management Network (NIC0): cloud0/oob/pnet0
resource "google_compute_network" "vdc_vpc1" {
  auto_create_subnetworks                   = false
  mtu                                       = 8896
  name                                      = "vdc-vpc1"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.gcp-project
  routing_mode                              = "REGIONAL"

  #depends_on = [google_project_service.compute_googleapis_com]
}


# vpc2: Cloud1 / pnet1 interface (will be the network used by pnetlab vRouters uplinks to Internet/NAT-network)
resource "google_compute_network" "vdc_vpc2" {
  auto_create_subnetworks                   = false
  mtu                                       = 8896
  name                                      = "vdc-vpc2"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.gcp-project
  routing_mode                              = "REGIONAL"

  #depends_on = [google_project_service.compute_googleapis_com]
}


# vpc3: Cloud2 / pnet2 interface (unused)
resource "google_compute_network" "vdc_vpc3" {
  auto_create_subnetworks                   = false
  mtu                                       = 8896
  name                                      = "vdc-vpc3"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.gcp-project
  routing_mode                              = "REGIONAL"

  #depends_on = [google_project_service.compute_googleapis_com]
}


# vpc4: Underlay NIC1 (Fabric Leg-A): Cloud3 / pnet3 
resource "google_compute_network" "vdc_vpc4" {
  auto_create_subnetworks                   = false
  mtu                                       = 8896
  name                                      = "vdc-vpc4"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.gcp-project
  routing_mode                              = "REGIONAL"

  #depends_on = [google_project_service.compute_googleapis_com]
}

# vpc5: Underlay NIC2 (for dual nic servers, fabric Leg-B) - cloud4 / pnet4
resource "google_compute_network" "vdc_vpc5" {
  auto_create_subnetworks                   = false
  mtu                                       = 8896
  name                                      = "vdc-vpc5"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.gcp-project
  routing_mode                              = "REGIONAL"

  #depends_on = [google_project_service.compute_googleapis_com]
}

# vpc6: Cloud5 / pnet5 interface (unused)
resource "google_compute_network" "vdc_vpc6" {
  auto_create_subnetworks                   = false
  mtu                                       = 8896
  name                                      = "vdc-vpc6"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.gcp-project
  routing_mode                              = "REGIONAL"

  #depends_on = [google_project_service.compute_googleapis_com]
}


# vpc7: Cloud6 / pnet6 interface (WAN with pub IP for vyos uplink / vpn-A)
resource "google_compute_network" "vdc_vpc7" {
  auto_create_subnetworks                   = false
  mtu                                       = 8896
  name                                      = "vdc-vpc7"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.gcp-project
  routing_mode                              = "REGIONAL"

  #depends_on = [google_project_service.compute_googleapis_com]
}

# vpc8: Cloud7 / pnet7 interface (WAN with pub IP for vyos uplink / vpn-B)
resource "google_compute_network" "vdc_vpc8" {
  auto_create_subnetworks                   = false
  mtu                                       = 8896
  name                                      = "vdc-vpc8"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.gcp-project
  routing_mode                              = "REGIONAL"

  #depends_on = [google_project_service.compute_googleapis_com]
}




















































# Subnetworks for each VPC 


# VPC1 subnets (servers management network)

resource "google_compute_subnetwork" "vdc_vpc1_net_10" {
  ip_cidr_range              = "10.10.10.0/24"
  name                       = "vdc-vpc1-net-10"
  network                    = google_compute_network.vdc_vpc1.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region

  # Used for routers oob interfaces.
  secondary_ip_range {
    ip_cidr_range = "10.10.15.0/24"
    range_name    = "secondary-vpc1-net-10-15"
  }

  # unused.
  secondary_ip_range {
    ip_cidr_range = "10.10.16.0/24"
    range_name    = "secondary-vpc1-net-10-16"
  }


  stack_type = "IPV4_ONLY"
}


locals {
  subnets-vpc1-rs = {
    "90" = "10.10.90.0/24",
    "91" = "10.10.91.0/24",
    "92" = "10.10.92.0/24",
    "93" = "10.10.93.0/24",
    "94" = "10.10.94.0/24",
    "95" = "10.10.95.0/24",
    "96" = "10.10.96.0/24",
    "97" = "10.10.97.0/24",
    "98" = "10.10.98.0/24",
    "99" = "10.10.99.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc1_net_rs" {
  for_each = local.subnets-vpc1-rs
  ip_cidr_range = each.value
  name          = "vdc-vpc1-net-rs-10-${each.key}"
  network                    = google_compute_network.vdc_vpc1.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
}

locals {
  subnets-vpc1-r0 = {
    "100" = "10.10.100.0/24",
    "101" = "10.10.101.0/24",
    "102" = "10.10.102.0/24",
    "103" = "10.10.103.0/24",
    "104" = "10.10.104.0/24",
    "105" = "10.10.105.0/24",
    "106" = "10.10.106.0/24",
    "107" = "10.10.107.0/24",
    "108" = "10.10.108.0/24",
    "109" = "10.10.109.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc1_net_r0" {
  for_each = local.subnets-vpc1-r0
  ip_cidr_range = each.value
  name          = "vdc-vpc1-net-r0-10-${each.key}"
  network                    = google_compute_network.vdc_vpc1.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc1_net_rs]
}

locals {
  subnets-vpc1-r1 = {
    "110" = "10.10.110.0/24",
    "111" = "10.10.111.0/24",
    "112" = "10.10.112.0/24",
    "113" = "10.10.113.0/24",
    "114" = "10.10.114.0/24",
    "115" = "10.10.115.0/24",
    "116" = "10.10.116.0/24",
    "117" = "10.10.117.0/24",
    "118" = "10.10.118.0/24",
    "119" = "10.10.119.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc1_net_r1" {
  for_each = local.subnets-vpc1-r1
  ip_cidr_range = each.value
  name          = "vdc-vpc1-net-r1-10-${each.key}"
  network                    = google_compute_network.vdc_vpc1.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc1_net_r0]
}

locals {
  subnets-vpc1-r2 = {
    "120" = "10.10.120.0/24",
    "121" = "10.10.121.0/24",
    "122" = "10.10.122.0/24",
    "123" = "10.10.123.0/24",
    "124" = "10.10.124.0/24",
    "125" = "10.10.125.0/24",
    "126" = "10.10.126.0/24",
    "127" = "10.10.127.0/24",
    "128" = "10.10.128.0/24",
    "129" = "10.10.129.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc1_net_r2" {
  for_each = local.subnets-vpc1-r2
  ip_cidr_range = each.value
  name          = "vdc-vpc1-net-r2-10-${each.key}"
  network                    = google_compute_network.vdc_vpc1.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc1_net_r1]
}

locals {
  subnets-vpc1-r3 = {
    "130" = "10.10.130.0/24",
    "131" = "10.10.131.0/24",
    "132" = "10.10.132.0/24",
    "133" = "10.10.133.0/24",
    "134" = "10.10.134.0/24",
    "135" = "10.10.135.0/24",
    "136" = "10.10.136.0/24",
    "137" = "10.10.137.0/24",
    "138" = "10.10.138.0/24",
    "139" = "10.10.139.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc1_net_r3" {
  for_each = local.subnets-vpc1-r3
  ip_cidr_range = each.value
  name          = "vdc-vpc1-net-r3-10-${each.key}"
  network                    = google_compute_network.vdc_vpc1.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc1_net_r2]
}


locals {
  subnets-vpc1-r4 = {
    "130" = "10.10.140.0/24",
    "131" = "10.10.141.0/24",
    "132" = "10.10.142.0/24",
    "133" = "10.10.143.0/24",
    "134" = "10.10.144.0/24",
    "135" = "10.10.145.0/24",
    "136" = "10.10.146.0/24",
    "137" = "10.10.147.0/24",
    "138" = "10.10.148.0/24",
    "139" = "10.10.149.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc1_net_r4" {
  for_each = local.subnets-vpc1-r4
  ip_cidr_range = each.value
  name          = "vdc-vpc1-net-r4-10-${each.key}"
  network                    = google_compute_network.vdc_vpc1.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc1_net_r3]
}





resource "google_compute_subnetwork" "vdc_vpc2_net_20" {
  ip_cidr_range              = "10.10.20.0/24"
  name                       = "vdc-vpc2-net-20"
  network                    = google_compute_network.vdc_vpc2.id
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region

  secondary_ip_range {
    ip_cidr_range = "10.10.25.0/24"
    range_name    = "secondary-vpc2-net-20-25"
  }
  secondary_ip_range {
    ip_cidr_range = "10.10.26.0/24"
    range_name    = "secondary-vpc2-net-20-26"
  }

  stack_type = "IPV4_ONLY"
}

resource "google_compute_subnetwork" "vdc_vpc3_net_30" {
  ip_cidr_range              = "10.10.30.0/24"
  name                       = "vdc-vpc3-net-30"
  network                    = google_compute_network.vdc_vpc3.id
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region

  secondary_ip_range {
    ip_cidr_range = "10.10.35.0/24"
    range_name    = "secondary-vpc3-net-30-35"
  }
  secondary_ip_range {
    ip_cidr_range = "10.10.36.0/24"
    range_name    = "secondary-vpc3-net-30-36"
  }

  stack_type = "IPV4_ONLY"
}


resource "google_compute_subnetwork" "vdc_vpc4_net_40" {
  ip_cidr_range              = "10.10.40.0/24"
  name                       = "vdc-vpc4-net-40"
  network                    = google_compute_network.vdc_vpc4.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region

  # Used for routers oob interfaces.
  secondary_ip_range {
    ip_cidr_range = "10.10.45.0/24"
    range_name    = "secondary-vpc4-net-40-45"
  }
  secondary_ip_range {
    ip_cidr_range = "10.10.46.0/24"
    range_name    = "secondary-vpc4-net-40-46"
  }
  stack_type = "IPV4_ONLY"
}


locals {
  subnets-vpc4-rs = {
    "90" = "10.40.90.0/24",
    "91" = "10.40.91.0/24",
    "92" = "10.40.92.0/24",
    "93" = "10.40.93.0/24",
    "94" = "10.40.94.0/24",
    "95" = "10.40.95.0/24",
    "96" = "10.40.96.0/24",
    "97" = "10.40.97.0/24",
    "98" = "10.40.98.0/24",
    "99" = "10.40.99.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc4_net_rs" {
  for_each = local.subnets-vpc4-rs

  ip_cidr_range              = each.value
  name                       = "vdc-vpc4-net-rs-40-${each.key}"
  network                    = google_compute_network.vdc_vpc4.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
}

locals {
  subnets-vpc4-r0 = {
    "100" = "10.40.100.0/24",
    "101" = "10.40.101.0/24",
    "102" = "10.40.102.0/24",
    "103" = "10.40.103.0/24",
    "104" = "10.40.104.0/24",
    "105" = "10.40.105.0/24",
    "106" = "10.40.106.0/24",
    "107" = "10.40.107.0/24",
    "108" = "10.40.108.0/24",
    "109" = "10.40.109.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc4_net_r0" {
  for_each = local.subnets-vpc4-r0

  ip_cidr_range              = each.value
  name                       = "vdc-vpc4-net-r0-40-${each.key}"
  network                    = google_compute_network.vdc_vpc4.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc4_net_rs]
}


locals {
  subnets-vpc4-r1 = {
    "110" = "10.40.110.0/24",
    "111" = "10.40.111.0/24",
    "112" = "10.40.112.0/24",
    "113" = "10.40.113.0/24",
    "114" = "10.40.114.0/24",
    "115" = "10.40.115.0/24",
    "116" = "10.40.116.0/24",
    "117" = "10.40.117.0/24",
    "118" = "10.40.118.0/24",
    "119" = "10.40.119.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc4_net_r1" {
  for_each = local.subnets-vpc4-r1

  ip_cidr_range              = each.value
  name                       = "vdc-vpc4-net-r1-40-${each.key}"
  network                    = google_compute_network.vdc_vpc4.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc4_net_r0]
}

locals {
  subnets-vpc4-r2 = {
    "120" = "10.40.120.0/24",
    "121" = "10.40.121.0/24",
    "122" = "10.40.122.0/24",
    "123" = "10.40.123.0/24",
    "124" = "10.40.124.0/24",
    "125" = "10.40.125.0/24",
    "126" = "10.40.126.0/24",
    "127" = "10.40.127.0/24",
    "128" = "10.40.128.0/24",
    "129" = "10.40.129.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc4_net_r2" {
  for_each = local.subnets-vpc4-r2

  ip_cidr_range              = each.value
  name                       = "vdc-vpc4-net-r2-40-${each.key}"
  network                    = google_compute_network.vdc_vpc4.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc4_net_r1]
}

locals {
  subnets-vpc4-r3 = {
    "130" = "10.40.130.0/24",
    "131" = "10.40.131.0/24",
    "132" = "10.40.132.0/24",
    "133" = "10.40.133.0/24",
    "134" = "10.40.134.0/24",
    "135" = "10.40.135.0/24",
    "136" = "10.40.136.0/24",
    "137" = "10.40.137.0/24",
    "138" = "10.40.138.0/24",
    "139" = "10.40.139.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc4_net_r3" {
  for_each = local.subnets-vpc4-r3

  ip_cidr_range              = each.value
  name                       = "vdc-vpc4-net-r3-40-${each.key}"
  network                    = google_compute_network.vdc_vpc4.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc4_net_r2]
}


locals {
  subnets-vpc4-r4 = {
    "140" = "10.40.140.0/24",
    "141" = "10.40.141.0/24",
    "142" = "10.40.142.0/24",
    "143" = "10.40.143.0/24",
    "144" = "10.40.144.0/24",
    "145" = "10.40.145.0/24",
    "146" = "10.40.146.0/24",
    "147" = "10.40.147.0/24",
    "148" = "10.40.148.0/24",
    "149" = "10.40.149.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc4_net_r4" {
  for_each = local.subnets-vpc4-r4

  ip_cidr_range              = each.value
  name                       = "vdc-vpc4-net-r4-40-${each.key}"
  network                    = google_compute_network.vdc_vpc4.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc4_net_r3]
}




resource "google_compute_subnetwork" "vdc_vpc5_net_50" {
  ip_cidr_range              = "10.10.50.0/24"
  name                       = "vdc-vpc5-net-50"
  network                    = google_compute_network.vdc_vpc5.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region

  # Used for routers oob interfaces.
  secondary_ip_range {
    ip_cidr_range = "10.10.55.0/24"
    range_name    = "secondary-vpc5-net-50-55"
  }
  secondary_ip_range {
    ip_cidr_range = "10.10.56.0/24"
    range_name    = "secondary-vpc5-net-50-56"
  }
  stack_type = "IPV4_ONLY"
}

locals {
  subnets-vpc5-rs = {
    "90" = "10.50.90.0/24",
    "91" = "10.50.91.0/24",
    "92" = "10.50.92.0/24",
    "93" = "10.50.93.0/24",
    "94" = "10.50.94.0/24",
    "95" = "10.50.95.0/24",
    "96" = "10.50.96.0/24",
    "97" = "10.50.97.0/24",
    "98" = "10.50.98.0/24",
    "99" = "10.50.99.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc5_net_rs" {
  for_each = local.subnets-vpc5-rs

  ip_cidr_range              = each.value
  name                       = "vdc-vpc5-net-rs-50-${each.key}"
  network                    = google_compute_network.vdc_vpc5.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
}

locals {
  subnets-vpc5-r0 = {
    "100" = "10.50.100.0/24",
    "101" = "10.50.101.0/24",
    "102" = "10.50.102.0/24",
    "103" = "10.50.103.0/24",
    "104" = "10.50.104.0/24",
    "105" = "10.50.105.0/24",
    "106" = "10.50.106.0/24",
    "107" = "10.50.107.0/24",
    "108" = "10.50.108.0/24",
    "109" = "10.50.109.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc5_net_r0" {
  for_each = local.subnets-vpc5-r0

  ip_cidr_range              = each.value
  name                       = "vdc-vpc5-net-r0-50-${each.key}"
  network                    = google_compute_network.vdc_vpc5.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc5_net_rs]
}


locals {
  subnets-vpc5-r1 = {
    "110" = "10.50.110.0/24",
    "111" = "10.50.111.0/24",
    "112" = "10.50.112.0/24",
    "113" = "10.50.113.0/24",
    "114" = "10.50.114.0/24",
    "115" = "10.50.115.0/24",
    "116" = "10.50.116.0/24",
    "117" = "10.50.117.0/24",
    "118" = "10.50.118.0/24",
    "119" = "10.50.119.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc5_net_r1" {
  for_each = local.subnets-vpc5-r1

  ip_cidr_range              = each.value
  name                       = "vdc-vpc5-net-r1-50-${each.key}"
  network                    = google_compute_network.vdc_vpc5.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc5_net_r0]
}

locals {
  subnets-vpc5-r2 = {
    "120" = "10.50.120.0/24",
    "121" = "10.50.121.0/24",
    "122" = "10.50.122.0/24",
    "123" = "10.50.123.0/24",
    "124" = "10.50.124.0/24",
    "125" = "10.50.125.0/24",
    "126" = "10.50.126.0/24",
    "127" = "10.50.127.0/24",
    "128" = "10.50.128.0/24",
    "129" = "10.50.129.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc5_net_r2" {
  for_each = local.subnets-vpc5-r2

  ip_cidr_range              = each.value
  name                       = "vdc-vpc5-net-r2-50-${each.key}"
  network                    = google_compute_network.vdc_vpc5.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc5_net_r1]
}

locals {
  subnets-vpc5-r3 = {
    "130" = "10.50.130.0/24",
    "131" = "10.50.131.0/24",
    "132" = "10.50.132.0/24",
    "133" = "10.50.133.0/24",
    "134" = "10.50.134.0/24",
    "135" = "10.50.135.0/24",
    "136" = "10.50.136.0/24",
    "137" = "10.50.137.0/24",
    "138" = "10.50.138.0/24",
    "139" = "10.50.139.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc5_net_r3" {
  for_each = local.subnets-vpc5-r3

  ip_cidr_range              = each.value
  name                       = "vdc-vpc5-net-r3-50-${each.key}"
  network                    = google_compute_network.vdc_vpc5.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc5_net_r2]
}


locals {
  subnets-vpc5-r4 = {
    "140" = "10.50.140.0/24",
    "141" = "10.50.141.0/24",
    "142" = "10.50.142.0/24",
    "143" = "10.50.143.0/24",
    "144" = "10.50.144.0/24",
    "145" = "10.50.145.0/24",
    "146" = "10.50.146.0/24",
    "147" = "10.50.147.0/24",
    "148" = "10.50.148.0/24",
    "149" = "10.50.149.0/24",
  }
}
resource "google_compute_subnetwork" "vdc_vpc5_net_r4" {
  for_each = local.subnets-vpc5-r4

  ip_cidr_range              = each.value
  name                       = "vdc-vpc5-net-r4-50-${each.key}"
  network                    = google_compute_network.vdc_vpc5.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region
  stack_type                 = "IPV4_ONLY"
  
  depends_on = [google_compute_subnetwork.vdc_vpc5_net_r3]
}






resource "google_compute_subnetwork" "vdc_vpc6_net_60" {
  ip_cidr_range              = "10.10.60.0/24"
  name                       = "vdc-vpc6-net-60"
  network                    = google_compute_network.vdc_vpc6.id
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region

  secondary_ip_range {
    ip_cidr_range = "10.10.65.0/24"
    range_name    = "secondary-vpc6-net-60-65"
  }
  secondary_ip_range {
    ip_cidr_range = "10.10.66.0/24"
    range_name    = "secondary-vpc6-net-60-66"
  }
  stack_type = "IPV4_ONLY"
}

resource "google_compute_subnetwork" "vdc_vpc7_net_70" {
  ip_cidr_range              = "10.10.70.0/24"
  name                       = "vdc-vpc7-net-70"
  network                    = google_compute_network.vdc_vpc7.id
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region

  secondary_ip_range {
    ip_cidr_range = "10.10.75.0/24"
    range_name    = "secondary-vpc7-net-70-75"
  }
  secondary_ip_range {
    ip_cidr_range = "10.10.76.0/24"
    range_name    = "secondary-vpc7-net-70-76"
  }
  stack_type = "IPV4_ONLY"
}


resource "google_compute_subnetwork" "vdc_vpc8_net_80" {
  ip_cidr_range              = "10.10.80.0/24"
  name                       = "vdc-vpc8-net-80"
  network                    = google_compute_network.vdc_vpc8.id
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = local.gcp-project
  purpose                    = "PRIVATE"
  region                     = local.gcp-region

  secondary_ip_range {
    ip_cidr_range = "10.10.85.0/24"
    range_name    = "secondary-vpc8-net-80-85"
  }
  secondary_ip_range {
    ip_cidr_range = "10.10.86.0/24"
    range_name    = "secondary-vpc8-net-80-86"
  }
  stack_type = "IPV4_ONLY"
}






























































##06-VPC-Firewall



# FIREWALL

# vpc1 firewall
resource "google_compute_firewall" "ingress_all_vpc1" {
  allow {
    protocol = "all"
  }
  direction     = "INGRESS"
  name          = "ingress-all-vpc1"
  network       = google_compute_network.vdc_vpc1.id
  priority      = 999
  project       = local.gcp-project
  source_ranges = ["0.0.0.0/0"]
}

# resource "google_compute_firewall" "ingress_pnet_ui" {
#   allow {
#     ports    = ["0-65535"]
#     protocol = "tcp"
#   }

#   direction     = "INGRESS"
#   name          = "ingress-pnet-ui"
#   network       = google_compute_network.vdc_vpc1.id
#   priority      = 1000
#   project       = local.gcp-project
#   source_ranges = ["0.0.0.0/0"]
# }

# resource "google_compute_firewall" "vdc_vpc1_allow_http" {
#   allow {
#     ports    = ["80"]
#     protocol = "tcp"
#   }

#   direction     = "INGRESS"
#   name          = "vdc-vpc1-allow-http"
#   network       = google_compute_network.vdc_vpc1.id
#   priority      = 1000
#   project       = local.gcp-project
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["http-server"]
# }

# resource "google_compute_firewall" "vdc_vpc1_allow_icmp" {
#   allow {
#     protocol = "icmp"
#   }

#   description   = "Allows ICMP connections from any source to any instance on the network."
#   direction     = "INGRESS"
#   name          = "vdc-vpc1-allow-icmp"
#   network       = google_compute_network.vdc_vpc1.id
#   priority      = 65534
#   project       = local.gcp-project
#   source_ranges = ["0.0.0.0/0"]
# }

# resource "google_compute_firewall" "vdc_vpc1_allow_rdp" {
#   allow {
#     ports    = ["3389"]
#     protocol = "tcp"
#   }

#   description   = "Allows RDP connections from any source to any instance on the network using port 3389."
#   direction     = "INGRESS"
#   name          = "vdc-vpc1-allow-rdp"
#   network       = google_compute_network.vdc_vpc1.id
#   priority      = 65534
#   project       = local.gcp-project
#   source_ranges = ["0.0.0.0/0"]
# }

# resource "google_compute_firewall" "vdc_vpc1_allow_ssh" {
#   allow {
#     ports    = ["22"]
#     protocol = "tcp"
#   }

#   description   = "Allows TCP connections from any source to any instance on the network using port 22."
#   direction     = "INGRESS"
#   name          = "vdc-vpc1-allow-ssh"
#   network       = google_compute_network.vdc_vpc1.id
#   priority      = 65534
#   project       = local.gcp-project
#   source_ranges = ["0.0.0.0/0"]
# }

# resource "google_compute_firewall" "vdc_vpc1_allow_custom" {
#   allow {
#     protocol = "all"
#   }

#   description   = "Allows connection from any source to any instance on the network using custom protocols."
#   direction     = "INGRESS"
#   name          = "vdc-vpc1-allow-custom"
#   network       = google_compute_network.vdc_vpc1.id
#   priority      = 65534
#   project       = local.gcp-project
#   source_ranges = ["10.10.10.0/24"]
# }


resource "google_compute_firewall" "egress_all_vpc1" {
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  direction          = "EGRESS"
  name               = "egress-all-vpc1"
  network            = google_compute_network.vdc_vpc1.id
  priority           = 999
  project            = local.gcp-project
}


# vpc4 firewall
resource "google_compute_firewall" "ingress_all_vpc4" {
  allow {
    protocol = "all"
  }
  direction     = "INGRESS"
  name          = "ingress-all-vpc4"
  network       = google_compute_network.vdc_vpc4.id
  priority      = 999
  project       = local.gcp-project
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "egress_all_vpc4" {
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  direction          = "EGRESS"
  name               = "egress-all-vpc4"
  network            = google_compute_network.vdc_vpc4.id
  priority           = 999
  project            = local.gcp-project
}



# vpc5 firewall
resource "google_compute_firewall" "ingress_all_vpc5" {
  allow {
    protocol = "all"
  }
  direction     = "INGRESS"
  name          = "ingress-all-vpc5"
  network       = google_compute_network.vdc_vpc5.id
  priority      = 999
  project       = local.gcp-project
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "egress_all_vpc5" {
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  direction          = "EGRESS"
  name               = "egress-all-vpc5"
  network            = google_compute_network.vdc_vpc5.id
  priority           = 999
  project            = local.gcp-project
}









































































##07-Cloud-NAT



# NAT: We use cloud NAT for 
# - the primary ip of servers deployed to vpc1 to have access to the internet (e.g. apt-update...)
# - the network used by the Edge routers' uplinks to access the internet.check
# - the WAN networks (vpc6 and vpc7)


resource "google_compute_router" "vdc_vpc1_cloud_router" {
  name    = "vdc-vpc1-cloud-router"
  network = google_compute_network.vdc_vpc1.id
  region  = google_compute_subnetwork.vdc_vpc1_net_10.region
}

resource "google_compute_router_nat" "vdc_vpc1_nat" {
  name                               = "vdc-vpc1-nat"
  router                             = google_compute_router.vdc_vpc1_cloud_router.name
  region                             = google_compute_router.vdc_vpc1_cloud_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}




# vpc2 is used for internet uplink of Edge Routers (cloud1/pnet1/vpc2). So need cloud NAT. 
resource "google_compute_router" "vdc_vpc2_cloud_router" {
  name    = "vdc-vpc2-cloud-router"
  network = google_compute_network.vdc_vpc2.id
  region  = google_compute_subnetwork.vdc_vpc2_net_20.region
}

resource "google_compute_router_nat" "vdc_vpc2_nat" {
  name                               = "vdc-vpc2-nat"
  router                             = google_compute_router.vdc_vpc2_cloud_router.name
  region                             = google_compute_router.vdc_vpc2_cloud_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}



# vpc7 is used for VPN/WAN uplink-B of CE-A (cloud6/pnet6/vpc7). So need cloud NAT to static IP.
resource "google_compute_router" "vdc_vpc7_cloud_router" {
  name    = "vdc-vpc7-cloud-router"
  network = google_compute_network.vdc_vpc7.id
  region  = google_compute_subnetwork.vdc_vpc7_net_70.region
}

resource "google_compute_router_nat" "vdc_vpc7_nat" {
  name                               = "vdc-vpc7-nat"
  router                             = google_compute_router.vdc_vpc7_cloud_router.name
  region                             = google_compute_router.vdc_vpc7_cloud_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# vpc8 is used for VPN/WAN uplink-B of CE-B (cloud7/pnet7/vpc8). So need cloud NAT to static IP.
resource "google_compute_router" "vdc_vpc8_cloud_router" {
  name    = "vdc-vpc8-cloud-router"
  network = google_compute_network.vdc_vpc8.id
  region  = google_compute_subnetwork.vdc_vpc8_net_80.region
}

resource "google_compute_router_nat" "vdc_vpc8_nat" {
  name                               = "vdc-vpc8-nat"
  router                             = google_compute_router.vdc_vpc8_cloud_router.name
  region                             = google_compute_router.vdc_vpc8_cloud_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}















































































#-> now in main.sh Create <project>-bucket bucket:
# resource "google_storage_bucket" "project_bucket" {
#   name          = "vdc-tf-clone"
#   location      = local.gcp-region # Replace with your desired location [ypm] should change it to my zone of choice and not multi-region.
#   force_destroy = false            # Allow bucket deletion even with objects (use with caution)
# 
#   uniform_bucket_level_access = true # Recommended for consistent permissions
# }

#-> now in main.shmake gce-sa storage objectAdmin of bucket:
# resource "google_storage_bucket_iam_member" "project_bucket_iam" {
#   bucket = google_storage_bucket.project_bucket.name
#   role   = "roles/storage.objectAdmin"
#   member = "serviceAccount:${local.gce-sa}"
# }

## Clone Assets from source bucket to our bucket:
  ## Members of the vdc-assets-members@meillier.altostrat.com group can download assets to their bucket.
  ## Read-only access to bucket was provided with:
  ## Yannick Meillier (argolis) owned bucket hosted on vdc-tf project: gs://vdc-tf-bucket
  ## gcloud storage buckets add-iam-policy-binding gs://vdc-tf-bucket --member=group:vdc-assets-members@meillier.altostrat.com --role=roles/storage.objectViewer


#-> now in main.sh resource "null_resource" "bucket_cloning" {
#   triggers = {
#   # Re-run only if these values change.
#   # To force re-run on every apply, use something like: run_id = timestamp()
#   destination = google_storage_bucket.project_bucket.name
#   }
#   provisioner "local-exec" {
#     # This command will export the image to your local directory
#     command = "gsutil -m cp -r gs://vdc-tf-bucket/* gs://${google_storage_bucket.project_bucket.name}/"
#     interpreter = ["bash", "-c"]
#   }
# }


## #Below service account bucket access permission was added only so that my eve-ng project could access that bucket when testing container lab (needed to download vyos confgs from this bucket)
## resource "google_storage_bucket_iam_member" "project_bucket_iam-2" {
##   bucket = google_storage_bucket.project_bucket.name
##   role   = "roles/storage.objectAdmin"
##   member = "serviceAccount:${local.gce-sa-eve-ng-368801}"
## }




























































































































































# ##09-image-import <<<<<<<<<<<< DEPRECATED CODE SECTION....

# ##################################################################################################################################################################
# ##################################################################################################################################################################
# ################## Pnetlab-v5 using vmdk image import from source bucket (pnetlab installed but not labs), and import to local import bucket #########################################################
# ##################################################################################################################################################################
# ##################################################################################################################################################################
#
# ## SKIP
# ### Option 1: Upload vmdk from local filesystem to bucket (https://cloud.google.com/storage/docs/uploading-objects#terraform-upload-objects)
# ## Create a text object in Cloud Storage
# #
# ##            resource "google_storage_bucket_object" "default" {
# ##              name = "new-object"
# ##              # Use `source` or `content`
# ##              source       = "/path/to/an/object"
# ##              # content      = "Data as string to be uploaded"
# ##              content_type = "text/plain"
# ##              bucket       = google_storage_bucket.static.id
# ##            }
# ## OR
# ## 
# ##           resource "null_resource" "vmdk_gsutil_import_pnetlab_v5_custom" {
# ##            provisioner "local-exec" {
# ##              # This command will export the image to your local directory
# ##              command = <<EOT
# ##              #gsutil cp ./pnetlab-v5-custom-base.vmdk gs://${google_storage_bucket.project_bucket.name}/custom-images/pnetlab/pnetlab-v5-custom-base-imported.vmdk
# ##              gsutil cp ./test.txt gs://${google_storage_bucket.project_bucket.name}/custom-images/pnetlab/test-import.txt
# ##              EOT
# ##            }
# ##            #depends_on = [google_compute_image.pnetlab_v5_custom_base, google_storage_bucket_object.folder_pnetlab_images]
# ##            # lifecycle {
# ##            #   prevent_destroy = true
# ##            # }
# ##           }
#
#
#
#
#
# ## USE THIS
# ## Option 2: copy bucket object from one bucket to another https://cloud.google.com/storage/docs/moving-buckets#move-buckets
# ##      - Copy bucket content: gcloud storage cp --recursive gs://SOURCE_BUCKET/* gs://DESTINATION_BUCKET
# ##      - Copy bucket object: gcloud storage cp gs://SOURCE_BUCKET_NAME/SOURCE_OBJECT_NAME gs://DESTINATION_BUCKET_NAME/NAME_OF_COPY (https://cloud.google.com/storage/docs/copying-renaming-moving-objects#copy)
# ##      - Move bucket/rename object: gcloud storage mv gs://SOURCE_BUCKET_NAME/SOURCE_OBJECT_NAME gs://DESTINATION_BUCKET_NAME/DESTINATION_OBJECT_NAME (https://cloud.google.com/storage/docs/copying-renaming-moving-objects#move)
#
#
# resource "google_storage_bucket" "project_bucket_import" {
#   name                        = "${local.gcp-project}-bucket-import"
#   location                    = local.gcp-region # Replace with your desired location [ypm] should change it to my zone of chocie and not multi-region.
#   force_destroy               = false            # Allow bucket deletion even with objects (use with caution)
#   uniform_bucket_level_access = true             # Recommended for consistent permissions
#   lifecycle {
#     prevent_destroy = true
#   }
# }
#
# data "external" "get_source_object_crc32c" {
#   program = [
#     "bash",
#     "-c",
#     <<-EOT
#       gsutil hash -m "gs://${google_storage_bucket.project_bucket.name}/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk" | \
#       awk '/Hash \(crc32c\)/ {printf "{\"crc32c\": \"%s\"}", substr($0, 18, 8)}'
#     EOT
#   ]
# }
# resource "null_resource" "import_pnetlab_from_bucket" {
#   triggers = {
#     source_object_crc32c = data.external.get_source_object_crc32c.result.crc32c
#     #condition to trigger the local-exec command: if the source_object_md5 is different than when the resource was previously evaluated.
#   }
#   provisioner "local-exec" {
#     #command = "gcloud storage cp --recursive gs://${google_storage_bucket.source_bucket.name}/* gs://${google_storage_bucket.destination_bucket.name}"
#     command = "gcloud storage cp gs://${google_storage_bucket.project_bucket.name}/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk gs://${google_storage_bucket.project_bucket_import.name}/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk"
#   }
# }
#
#
# # Or could have used storage transfer service
# ##
# ## resource "google_project_service" "storagetransfer_api" {
# ##   project            = local.gcp-project
# ##   service            = "storagetransfer.googleapis.com"
# ##   disable_on_destroy = false # Set to true to disable on destroy
# ## }
# ##
# ## resource "google_project_iam_member" "sts_objectadmin" {
# ##   project = local.gcp-project
# ##   role    = "roles/storage.objectAdmin"
# ##   member  = "serviceAccount:${local.storagetransfer-sa}"
# ## }
# ##
# ## resource "google_project_iam_member" "sts_admin" {
# ##   project = local.gcp-project
# ##   role    = "roles/storage.admin"
# ##   member  = "serviceAccount:${local.storagetransfer-sa}"
# ## }
# ##
# ## resource "google_storage_transfer_job" "gcs_to_gcs_transfer" {
# ##   project = local.gcp-project # project of source
# ##   description = "Copy object between GCS buckets"
# ##
# ##   transfer_spec {
# ##     gcs_data_source {
# ##       bucket_name = "${google_storage_bucket.project_bucket.name}"
# ##       #path = "custom-images/pnetlab/"
# ##     }
# ##     gcs_data_sink {
# ##       bucket_name = "${google_storage_bucket.project_bucket_import.name}"
# ##       #path = "custom-images/pnetlab/" - with that in the destination bucket file ended up in bucket assets-pnetlab>custom-images>pnetlab>custom-image>pnetlab
# ##     }
# ##     object_conditions {
# ##       include_prefixes = ["custom-images/pnetlab/pnetlab-v5-custom-base.vmdk"] 
# ##     }
# ##     transfer_options {
# ##       #delete_objects_unique_in_sink = false  # Don't delete objects in the destination
# ##       delete_objects_from_source_after_transfer = false
# ##       overwrite_objects_already_existing_in_sink = true  # Overwrite if the object exists
# ##     }
# ##   }
# ##   depends_on = [ google_storage_bucket.project_bucket_import ]
# ## }
# ##
# ## ##gcloud transfer jobs list
# ## ##gcloud transfer operations list
# ##
# ## resource "null_resource" "run_transfer" {
# ##   triggers = {
# ##     job_id = google_storage_transfer_job.gcs_to_gcs_transfer.name
# ##   }
# ##   provisioner "local-exec" {
# ##     command = "gcloud transfer jobs run ${google_storage_transfer_job.gcs_to_gcs_transfer.name} --project ${google_storage_transfer_job.gcs_to_gcs_transfer.project}"
# ##   }
# ##   depends_on = [
# ##     google_storage_transfer_job.gcs_to_gcs_transfer
# ##   ]
# ## }
#
#
#
#
#
#
#
# ## Step 2: Import image from bucket to compute engine - so it shows in gcloud compute images list (https://cloud.google.com/migrate/virtual-machines/docs/5.0/migrate/image_import#gcloud ; more info at https://cloud.google.com/sdk/gcloud/reference/migration/vms/image-imports)
#
#
#
# ## Import with gcloud copmute images import , which will be deprecated in favor of gcloud migration vms image-imports
# ## https://cloud.google.com/sdk/gcloud/reference/compute/images/import
#
#
#
# # # ## Option 1: This failed: because of deprecation???
# # ## For export we had used: 
# # ##gcloud compute images export --destination-uri=gs://vdc-tf-bucket/test-gcloud.vmdk --image=vdc-pnetlab-v5-image-base --project=vdc-tf --export-format=vmdk --network=vdc-vpc1 --subnet=vdc-vpc1-net-10
# #
# # ## This failed: because of deprecation???
#--source-file=vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk \
#
# # gcloud compute images import vdc-pnetlab-v5-image-base-imported \
# # --source-uri=vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk \
# # --network=vdc-vpc1 --subnet=vdc-vpc1-net-10 \
# # --family=vdc-pnetlab-images \
# # --project=vdc-tf2 \
# # --storage-location=us-central1
# #
# # resource "null_resource" "image_import_pnetlab_v5" {
# #   provisioner "local-exec" {
# #     # This command will export the image to your local directory
# #     command = <<EOT
# #     gcloud compute images import vdc-pnetlab-v5-image-base-v2 \
# #     --family=vdc-pnetlab-images \
# #     --source-file=gs://${google_storage_bucket.project_bucket_import.name}/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk \
# #     --network=${google_compute_network.vdc_vpc1.name} \
# #     --subnet=${google_compute_subnetwork.vdc_vpc1_net_10.name} \
# #     --project=${local.gcp-project} \
# #     --storage-location=${local.gcp-region}
# #     EOT
# #   }
# #   depends_on = [data.google_storage_bucket_object.object_check, google_compute_image.pnetlab_v5_custom_base, google_storage_bucket_object.folder_pnetlab_images]
# #   lifecycle {
# #     prevent_destroy = true
# #   }
# # }




# # ##Option 2:  Requires adding our project as a target project via console (no gcloud option) : https://cloud.google.com/migrate/virtual-machines/docs/5.0/get-started/target-project

#-> now in main.sh 
# #Setup target project: enable services - https://cloud.google.com/migrate/virtual-machines/docs/5.0/get-started/target-project#identify
# 
# resource "google_project_service" "vmmigration_api" {
#   project            = local.gcp-project
#   service            = "vmmigration.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }
# 
# resource "google_project_service" "svcmgmt_api" {
#   project            = local.gcp-project
#   service            = "servicemanagement.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }
# 
# resource "google_project_service" "svctrl_api" {
#   project            = local.gcp-project
#   service            = "servicecontrol.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }
# 
# resource "google_project_service" "iam_api" {
#   project            = local.gcp-project
#   service            = "iam.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }
# 
# resource "google_project_service" "cloudresmgr_api" {
#   project            = local.gcp-project
#   service            = "cloudresourcemanager.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }



# Console/manual step: Add project as target to Migrate to Virtual Machines: https://cloud.google.com/migrate/virtual-machines/docs/5.0/get-started/target-project#add-project
## Adding a target project will give the Migrate to Virtual Machines service account service-846229250908@gcp-sa-vmmigration.iam.gserviceaccount.com the following role on the project: VM Migration Service Agent.
## Validate presence of target project with: gcloud alpha migration vms target-projects list -> projects/vdc-tf/locations/global/targetProjects/vdc-tf
# 1. / --> on your current project, go to: https://console.cloud.google.com/compute/mfce
# 2. target tab, add your project as target project (you are also the host project in this case)
# #or cli? --> not yet supporting adding project as target project... need GUI
# # 3. verify with gcloud alpha migration vms target-projects list
# -

#vm migration managed service account roles
#https://cloud.google.com/migrate/virtual-machines/docs/5.0/migrate/image_import#permissions

# #--> in main.sh Migrate to Virtual Machines service account in the host project needs access to storage bucket on host project (where image stored)
# resource "google_project_iam_member" "vmmigration_sa_storageviewer" {
#   project = local.gcp-project
#   role    = "roles/storage.objectViewer"
#   member  = "serviceAccount:service-${local.gcp-project-number}@gcp-sa-vmmigration.iam.gserviceaccount.com"
# }

## resource "google_project_iam_member" "storageobjectviewer_sa_vm_migration" {
##   project = local.gcp-project
##   role    = "roles/storage.objectViewer"
##   member  = "serviceAccount:service-${local.gcp-project-number}@gcp-sa-vmmigration.iam.gserviceaccount.com"
## }


# #--> now done in main.sh: User doing the import needs vmmigration admin permissions:
# resource "google_project_iam_member" "user_vmmigrationadmin" {
#   project = local.gcp-project
#   role    = "roles/vmmigration.admin"
#   member  = "user:${local.user-account}"
# }
# ## gcloud projects add-iam-policy-binding $PROJECT_ID --member="user:${ACCOUNT}" --role="roles/vmmigration.admin"

# #--> now done in main.sh: Migrate to Virtual Machines service account in the host project needs serviceAgent role:
# resource "google_project_iam_member" "vmmigration_sa_vmmigrationagent" {
#   project = local.gcp-project
#   role    = "roles/vmmigration.serviceAgent"
#   member  = "serviceAccount:service-${local.gcp-project-number}@gcp-sa-vmmigration.iam.gserviceaccount.com"
# }


## ACCOUNT="service-250796033514@gcp-sa-vmmigration.iam.gserviceaccount.com"
## PROJECT_ID="vdc-tf2"
## gcloud projects get-ancestors-iam-policy $PROJECT_ID --flatten policy.bindings[].members --filter policy.bindings.members:serviceAccount:$ACCOUNT
##
## ACCOUNT="admin@meillier.altostrat.com"
## PROJECT_ID="vdc-tf2"
## gcloud projects get-ancestors-iam-policy $PROJECT_ID --flatten policy.bindings[].members --filter policy.bindings.members:user:$ACCOUNT
##
##
## #On bucket??? 
## #make "service-${local.gcp-project-number}@gcp-sa-vmmigration.iam.gserviceaccount.com" storage objectAdmin of bucket:
## resource "google_storage_bucket_iam_member" "vmmigration_sa" {
##   bucket = google_storage_bucket.project_bucket.name
##   role   = "roles/storage.objectViewer"
##   member = "serviceAccount:service-${local.gcp-project-number}@gcp-sa-vmmigration.iam.gserviceaccount.com"
## }
##
## resource "google_storage_bucket_iam_member" "user" {
##   bucket = google_storage_bucket.project_bucket.name
##   role   = "roles/storage.objectViewer"
##   member = "user:${local.user-account}"
## }



##OLD --> use gcloud compute images create from .tar.gz exported image.
## resource "null_resource" "vmdk_bucket_image_import_pnetlab_v5_custom" {
##   # This provisioner has to wait for all necessary permissions to be set.
##   # The `local-exec` will not run until the dependencies are met.
##   # https://cloud.google.com/migrate/virtual-machines/docs/5.0/migrate/image_import#image_import_process
##   depends_on = [
##     google_project_iam_member.vmmigration_sa_vmmigrationagent,
##     google_project_iam_member.user_vmmigrationadmin,
##     google_project_iam_member.vmmigration_sa_storageviewer
##   ]
## 
##   provisioner "local-exec" {
##     ##gcloud migration vms image-imports create pnetlab-v5-custom-base-imported --source-file="gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk" --location=us-central1 --family-name=vdc-pnetlab-images --target-project=vdc-tf2
##     command = <<EOT
##     gcloud migration vms image-imports create pnetlab-v5-custom-base-imported \
##     --source-file=gs://${google_storage_bucket.project_bucket.name}/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk \
##     --location=${local.gcp-region} \
##     --family-name=vdc-pnetlab-images \
##     --target-project=${local.gcp-project}
##     EOT
##   }
## }
## # ## check status with:
## # gcloud compute images list | grep v5
## # gcloud migration vms image-imports list --location us-central1


# # # # Keep track of the image in the Terraform state without actively managing it with above resource .
# data "google_compute_image" "pnetlab_v5_custom_base_imported" {
#   name    = "pnetlab-v5-custom-base-imported" 
#   project = local.gcp-project 
# }
# 
# resource "null_resource" "image_update_trigger" {
#   triggers = {
#     # This value will change if the image is updated
#     image_id = data.google_compute_image.pnetlab_v5_custom_base_imported.id
#   }
# }
# 
# 
# data "google_compute_image" "pnetlab_v5_custom_base_imported-v2" {
#   name    = "pnetlab-v5-custom-base-imported-v2" 
#   project = local.gcp-project 
# }
# 
# resource "null_resource" "image_update_trigger-v2" {
#   triggers = {
#     # This value will change if the image is updated
#     image_id = data.google_compute_image.pnetlab_v5_custom_base_imported-v2.id
#   }
# }

























































































###11-Windows-Jump-Box
###################################################################################################################################################################
###################################################################################################################################################################
##################################################################### Windows Jump box ############################################################################
###################################################################################################################################################################
###################################################################################################################################################################
#
#
#
# [ypm]: Use a jump host name that includes the project otherwise in chrome remote desktop will have a lot of the same win-jh references...
# [ypm]: Figure out why web-preview with iap-tunnel or ssh -L does not work ... gcloud compute ssh <instance-name> -- -N -4 -L 8080:localhost:80

## Jump host: 
## https://cloud.google.com/architecture/chrome-desktop-remote-windows-compute-engine



# 1/ Generate auth code crd-auth-command.txt (temporary token that only lasts a few minues) via https://remotedesktop.google.com/headless 
#   to be stored locally in:  ${local.path-module}/assets-jump-host/crd-auth-command.txt
#   crd-auth-command.txt will be something like: "%PROGRAMFILES(X86)%\Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe" --code="4/0AanRRruwBAoELVkQa5R1lMQR8DuJgnbKscaPGdW7gTic_w7mz-imKqhJy0UZi7sKZPkNnQ" --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=%COMPUTERNAME%
#
#   Doc about RDP Auth setup: https://cloud.google.com/architecture/chrome-desktop-remote-windows-compute-engine#authorize_crd_service
#
#.  --> see main.sh for the creation of the file crd-sysprep-script.ps1



locals {
  crd_sysprep_script_ps1_content = file("${path.module}/assets-jump-host/crd-sysprep-script.ps1")
  #depends_on = [null_resource.crd_ps1_generate]
}







# If have to update .ps1 (token expired by time used it) run:
# tf apply -replace null_resource.crd_ps1_generate








variable "crd_pin" {
  type        = string
  description = "Chrome Remote Desktop (crd) pin"
  default     = "123456"
  sensitive   = false # Important for sensitive data
}

variable "crd_pass" {
  type        = string
  description = "password"
  default     = "Google1!"
  sensitive   = false # Important for sensitive data
}

# variable "instance_name" {
#   type        = string
#   description = "Instance name"
#   default     = "win-jh-${local.gcp-project-number}"
# }
locals {
  win_jh_instance_name     = "win-jh-${local.gcp-project-number}"
}


# Generate auth-code for any new crd setup: https://remotedesktop.google.com/headless 
locals {
  crd_auth_command_content = fileexists("./assets-jump-host/crd-auth-command.txt") ? file("./assets-jump-host/crd-auth-command.txt") : "dummy"
}


variable "admin_password" {
  type        = string
  description = "New password for the 'admin' user (INSECURE - DO NOT USE IN PRODUCTION)"
  sensitive   = true       # At least hide it in the state file
  default     = "Google1!" # Replace with a strong password for TESTING ONLY
}



# variable "crd_command" {
#   type        = string
#   description = "Chrome Remote Desktop (crd) command"
#   default     = local.crd_command_content
# }




## terraform apply -target=google_compute_instance.win_jh
## terraform destroy -target=google_compute_instance.win_jh
resource "google_compute_instance" "win_jh" {   
  name = local.win_jh_instance_name #name         = var.instance_name
  desired_status = "RUNNING"
  machine_type = "e2-medium"
  zone         = local.gcp-zone

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2022"
      size  = 50
    }
    device_name = local.win_jh_instance_name # device_name = var.instance_name
  }


  network_interface {
    network    = google_compute_network.vdc_vpc1.self_link
    subnetwork = google_compute_subnetwork.vdc_vpc1_net_10.self_link
    network_ip = "10.10.10.100"
  }

  # Scopes are handled differently in Terraform. This grants full cloud-platform access.
  service_account {
    scopes = ["cloud-platform"]
  }

  # Enable display device (equivalent to --enable-display-device)
  enable_display = true

  # Attach instance scheduling policies
  resource_policies = compact(concat(
    var.enable_auto_shutdown ? (length(google_compute_resource_policy.instance_shutdown_schedule) > 0 ? [google_compute_resource_policy.instance_shutdown_schedule[0].id] : []) : [],
    var.enable_auto_startup ? (length(google_compute_resource_policy.instance_startup_schedule) > 0 ? [google_compute_resource_policy.instance_startup_schedule[0].id] : []) : []
  ))

  # Shielded VM configuration - required for organization policy compliance
  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  metadata = {
    crd-pin                       = var.crd_pin
    crd-name                      = local.win_jh_instance_name
    crd-command                   = local.crd_auth_command_content
    crd-pass                      = var.crd_pass
    sysprep-specialize-script-ps1 = local.crd_sysprep_script_ps1_content
    # startup_script = metadata_startup_script = <<EOF
    #   <powershell>
    #   # Check if the marker file exists
    #   if (Test-Path -Path "C:\Windows\Temp\startup_script_completed.txt") {
    #   Write-Host "Startup script already executed. Exiting."
    #   exit
    #   }
    #   # Set the new password for the "admin" user (INSECURE - DO NOT USE IN PRODUCTION)
    #   $newPassword = ConvertTo-SecureString "${var.admin_password}" -AsPlainText -Force
    #   Set-LocalUser -Name "admin" -Password $newPassword
    #   # Create the marker file
    #   New-Item -ItemType File -Path "C:\Windows\Temp\startup_script_completed.txt" -Force
    #   Write-Host "Password for user 'admin' has been updated."
    #   </powershell>
    # EOF 
  }
  depends_on = [
    google_org_policy_policy.compute_requireShieldedVm,
    google_org_policy_policy.compute_vmCanIpForward,
    google_org_policy_policy.compute_vmExternalIpAccess,
    google_org_policy_policy.compute_disableSerialPortAccess,
    google_org_policy_policy.compute_requireOsLogin,
    google_org_policy_policy.compute_disableNestedVirtualization,
    google_org_policy_policy.allow_compute_image_import,
    google_compute_subnetwork.vdc_vpc1_net_10,
    #data.external.validate_compute_policies,
  ]
}

#
# #gcloud compute instances tail-serial-port-output win-jh-846229250908
#
#
#
#
#
# # # resource "null_resource" "monitor_jumphost" {
# # #   provisioner "local-exec" {
# # #     # This command will export the image to your local directory
# # #     command = "gcloud compute instances tail-serial-port-output ${local.win_jh_instance_name}"
# # #   }
# # # }
#
#
# # # 
#
# # # Startup script above did not work so have to reset password manually:
# # #gcloud compute reset-windows-password win-jh-846229250908
# # ## user = admin.
# # ##*EM)%1)0\e<{E1:


































































































# 
# ##08-PNET-LAB-Image-Build
# 
# 
# 
# #################################################################################################################################################################
# #################################################################################################################################################################
# ################## One-time Pnetlab installed via script and exported to vmdk in bucket #########################################################################
# ################## User would only need to copy vmdk from bucket to deploy their own pnetlab instance ###########################################################
# #################################################################################################################################################################
# #################################################################################################################################################################
# 
# 
# # Custom image with nesting (vmx): ubuntu_focal_nested (2004) and buntu_bionic_nested (1804)
# # The purpose is to create a new image that includes additional licenses—specifically ubuntu-pro-1804-lts/ubuntu-2004-lts and enable-vmx—which can only be applied when creating a new custom image from an existing disk or snapshot.
# 
# #gcloud commmands:
# # gcloud compute images list --show-deprecated | grep ubuntu
# # gcloud compute images create nested-ubuntu-focal --source-image-family=ubuntu-2004-lts --source-image-project=ubuntu-os-cloud --licenses https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx
# 
# # In terraform you have to create a disk first. The reason you have to create a persistent disk first in your Terraform code is that the google_compute_image resource is designed to create an image from an existing source disk or snapshot, not directly from a source image family. This design ensures that Terraform manages a specific, tangible resource (the disk) as a prerequisite, which it can track, modify, and delete as part of its state management.
# # The gcloud command, on the other hand, is an imperative tool. When you run gcloud compute images create ... --source-image-family=..., the command-line tool executes a series of actions on your behalf: it finds the latest image in the family, creates a temporary disk from it, creates the new image from that temporary disk, and then cleans up the disk. Terraform's design philosophy is to avoid these hidden, automated steps 
# 
# # ---- For pnetlab-v5 install (requires 1804/bionic) ----
# 
# ## data source to find the source image to use. This simply gets the metadata for the base Ubuntu image
# 
# #if wanted a specific image within the family and not the latest:
# data "google_compute_image" "ubuntu_1804_lts" {
#   name  = "ubuntu-pro-1804-bionic-v20241217"
#   #name  = "ubuntu-pro-1804-bionic-v20250828"
#   project = "ubuntu-os-pro-cloud"
# }
# 
# resource "google_compute_disk" "persistent_disk_1804lts" {
#   name  = "ubuntu-1804-pd"
#   image = data.google_compute_image.ubuntu_1804_lts.self_link
#   size  = 250
#   type  = "pd-ssd"
#   zone  = local.gcp-zone
# }
# 
# resource "google_compute_image" "ubuntu_bionic_nested" {
#   name              = "ubuntu-bionic-nested"
#   source_disk       = google_compute_disk.persistent_disk_1804lts.self_link
#   storage_locations = [local.gcp-region]
#   licenses          = ["https://www.googleapis.com/compute/v1/projects/ubuntu-os-pro-cloud/global/licenses/ubuntu-pro-1804-lts", "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"]
# }
# # The official images from the ubuntu-os-pro-cloud project already have the Ubuntu Pro license attached. The reason for adding the license explicitly when creating a custom image is that the license is not automatically carried over when you create a new image from a disk.
# # This is not the case for the free images from ubuntu-os-cloud project. Although we do respecify the license for the custom image, we techincally don't have to. 
# # enable-vmx is required for both to enable nested virtualization. The enable-vmx option is specified under the licenses field because Google Cloud's API uses licenses as a general mechanism to attach feature flags and specific configuration settings to an image.
# 
# 
# 
# ############################################################### Pnetlab Builder Step: instance ##################################################################################################################
# ## !!!!!Below Steps are only needed when generating new pnetlab base images (for example if new version of pnet comes out) - 
# #Once done, we export the vmdk so that it can be used as the base image for lab consumers. 
# #This will upload the vmdk to the bucket on vdc-tf (builder project). A bucket that is cloned in a new project by lab consumers.
# #--destination-uri=gs://vdc-tf-bucket/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk --image=vdc-pnetlab-v5-image-base
# 
# ## Create instances (from ubuntu base image with startup script for network stack customization, and then manual install of pnet-lab via code block "Interactive/manual pnet server configuration instructions"
# 
# # # ## pnetlab v5 (bionic) - from scratch (image is just ubuntu)
# resource "google_compute_instance" "vdc_pnetlab_v5_built" {
#   deletion_protection = false
# 
#   machine_type = "n2-highmem-8"
#   name         = "vdc-pnetlab-v5-built"
#   zone         = local.gcp-zone
# 
#   boot_disk {
#     initialize_params {
#       image = google_compute_image.ubuntu_bionic_nested.self_link
#     }
#     #mode = "READ_WRITE" # default
#   }
# 
#   can_ip_forward = true
#   enable_display = true
# 
#   network_interface {
#     nic_type    = "VIRTIO_NET"
#     queue_count = 0
#     stack_type  = "IPV4_ONLY"
#     subnetwork  = google_compute_subnetwork.vdc_vpc1_net_10.self_link
#     network_ip  = "10.10.10.215"
#     alias_ip_range {
#       ip_cidr_range         = "10.10.15.0/24"
#       subnetwork_range_name = "secondary-vpc1-net-10-15"
#     }
#   }
# 
#   network_interface {
#     nic_type    = "VIRTIO_NET"
#     queue_count = 0
#     stack_type  = "IPV4_ONLY"
#     subnetwork  = google_compute_subnetwork.vdc_vpc2_net_20.self_link
#     network_ip  = "10.10.20.215"
#     alias_ip_range {
#       ip_cidr_range         = "10.10.25.0/24"
#       subnetwork_range_name = "secondary-vpc2-net-20-25"
#     }
#   }
# 
#   network_interface {
#     nic_type    = "VIRTIO_NET"
#     queue_count = 0
#     stack_type  = "IPV4_ONLY"
#     subnetwork  = google_compute_subnetwork.vdc_vpc3_net_30.self_link
#     network_ip  = "10.10.30.215"
#     alias_ip_range {
#       ip_cidr_range         = "10.10.35.0/24"
#       subnetwork_range_name = "secondary-vpc3-net-30-35"
#     }
# 
#   }
# 
#   network_interface {
#     nic_type    = "VIRTIO_NET"
#     queue_count = 0
#     stack_type  = "IPV4_ONLY"
#     subnetwork  = google_compute_subnetwork.vdc_vpc4_net_40.self_link
#     network_ip  = "10.10.40.215"
#     alias_ip_range {
#       ip_cidr_range         = "10.10.45.0/24"
#       subnetwork_range_name = "secondary-vpc4-net-40-45"
#     }
#   }
# 
#   network_interface {
#     nic_type    = "VIRTIO_NET"
#     queue_count = 0
#     stack_type  = "IPV4_ONLY"
#     subnetwork  = google_compute_subnetwork.vdc_vpc5_net_50.self_link
#     network_ip  = "10.10.50.215"
#     alias_ip_range {
#       ip_cidr_range         = "10.10.55.0/24"
#       subnetwork_range_name = "secondary-vpc5-net-50-55"
#     }
#   }
# 
#   network_interface {
#     nic_type    = "VIRTIO_NET"
#     queue_count = 0
#     stack_type  = "IPV4_ONLY"
#     subnetwork  = google_compute_subnetwork.vdc_vpc6_net_60.self_link
#     network_ip  = "10.10.60.215"
#     alias_ip_range {
#       ip_cidr_range         = "10.10.65.0/24"
#       subnetwork_range_name = "secondary-vpc6-net-60-65"
#     }
#   }
# 
#   network_interface {
#     nic_type    = "VIRTIO_NET"
#     queue_count = 0
#     stack_type  = "IPV4_ONLY"
#     subnetwork  = google_compute_subnetwork.vdc_vpc7_net_70.self_link
#     network_ip  = "10.10.70.215"
#     alias_ip_range {
#       ip_cidr_range         = "10.10.75.0/24"
#       subnetwork_range_name = "secondary-vpc7-net-70-75"
#     }
#     access_config {
#       network_tier = "PREMIUM"
#     }
#   }
# 
#   network_interface {
#     nic_type    = "VIRTIO_NET"
#     queue_count = 0
#     stack_type  = "IPV4_ONLY"
#     subnetwork  = google_compute_subnetwork.vdc_vpc8_net_80.self_link
#     network_ip  = "10.10.80.215"
#     alias_ip_range {
#       ip_cidr_range         = "10.10.85.0/24"
#       subnetwork_range_name = "secondary-vpc8-net-80-85"
#     }
#     access_config {
#       network_tier = "PREMIUM"
#     }
#   }
# 
#   scheduling {
#     automatic_restart   = true
#     on_host_maintenance = "MIGRATE"
#     preemptible         = false
#     provisioning_model  = "STANDARD"
#   }
# 
#   service_account {
#     email  = local.gce-sa
#     scopes = ["https://www.googleapis.com/auth/devstorage.read_write", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
#     # made cloud storage api read_write vs read_only in case we want to write to the bucket via the SA.
#   }
# 
#   shielded_instance_config {
#     enable_integrity_monitoring = true
#     enable_secure_boot          = false
#     enable_vtpm                 = true
#   }
# 
#   depends_on = [
#     google_compute_subnetwork.vdc_vpc1_net_10,
#     google_compute_subnetwork.vdc_vpc2_net_20,
#     google_compute_subnetwork.vdc_vpc3_net_30,
#     google_compute_subnetwork.vdc_vpc4_net_40,
#     google_compute_subnetwork.vdc_vpc5_net_50,
#     google_compute_subnetwork.vdc_vpc6_net_60,
#     google_compute_subnetwork.vdc_vpc7_net_70,
#     google_compute_subnetwork.vdc_vpc8_net_80,
#     google_compute_image.ubuntu_bionic_nested
#   ]
# 
#   metadata = {
#     enable-oslogin     = "true"
#     serial-port-enable = "true"
#     startup-script     = <<EOF
#       #!/bin/bash
#       download_script() {
#         local script_name="$1"
#         local script_url="gs://${local.gcp-project}-bucket-clone/net-fix-scripts-pnetlab/$script_name" 
#        
#         if [[ -f "/root/$script_name" ]]; then
#           echo "File '$script_name' already exists. Skipping download."
#           return 0
#         fi
#        
#         echo "Downloading file with gsutil ..."        
#         gsutil cp "gs://${local.gcp-project}-bucket-clone/net-fix-scripts-pnetlab/$script_name" /tmp
# 
#  
# 
#         if [ $? -eq 0 ]; then # if last command successful (exitcode 0)
#           #sudo chmod +x "/tmp/$script_name"
#           sudo cp /tmp/"$script_name" /root
#           echo "File '$script_name' downloaded and placed in root."
#         else
#           echo "Error downloading script '$script_name' from '$script_url'. Please check URL and connectivity."
#           exit 1
#         fi
#       }
# 
#       # # use if slow pnetlab mirror - acrhives from 2025/01/03 for pnetlab v5 or has issues pulling:
#       #sudo gsutil -m cp -r "gs://${local.gcp-project}-bucket-clone/pnet-lab-binaries/apt-archives/*" /var/cache/apt/archives/
# 
#       ##Assets (normally only done after pnetlab was installed while this script is meant to be for doing new pnetlab installs. hence why is commented):
# 
#       sudo mkdir -p /downloads/
#       sudo gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/opt/ /downloads/
#       
#       #sudo gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/opt/unetlab/addons/ /downloads/opt/unetlab/
#       #sudo gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/opt/unetlab/html/ /downloads/opt/unetlab/
#       #sudo gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/opt/unetlab/labs/ /downloads/opt/unetlab/
#       
#       sudo gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/vyos-configs/ /downloads/
# 
# 
# 
# 
# 
#       
#       sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /root/.bashrc
#       sudo bash -c "source /root/.bashrc"
#       
#       # Download singlehomed and dualhomed scripts (to /root):
#       download_script routes-fix-all-final.sh.singlehomed
#       download_script routes-fix-all-final.sh.dualhomed  
#       ##not running route fix all yet so as not to hardwire interface configurations into the image we will export from this instance as a base image to use for further appliance deployment
#   
# 
#    EOF
#   }
# }
# #  
# # 
# # # ## Monitor deployment:
# # #   # gcloud compute instances tail-serial-port-output vdc-pnetlab-v5-built
# # #   # gcloud compute scp --tunnel-through-iap ./routes-fix-all-final.sh.singlehomed vdc-pnetlab-v5-built:~/tmp
# # #   # gcloud compute ssh --tunnel-through-iap vdc-pnetlab-v5-built
# # 
# # ########################################################################################################################################################################
# # ########################################################################################################################################################################
# # ### START OF: Interactive/manual pnet server configuration instructions
# # # sudo -i
# # echo 'root:pnet' | chpasswd #instead of interactive 'passwd'
# # sed -i -e "s/.*PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config
# # service sshd restart
# # #  
# 
# 
# 
# 
# ## normal process: Download packages from repo.pnetlab.com (and dependencies)
# 
#     # echo "deb [trusted=yes no-all=yes] https://repo.pnetlab.com /" >> /etc/apt/sources.list
#     #     # # No need to also have the http one: echo "deb [trusted=yes] https://repo.pnetlab.com ./" >> /etc/apt/sources.list
#     #     # this instead?
#     #     # echo "deb [trusted=yes no-all=yes] https://repo.pnetlab.com /" >> /etc/apt/sources.list
#     #     # #     # # #If apt-get update fails to pull from pnetlab because of cert issues.
#     #     # #     # #  # echo "deb [trusted=yes allow-insecure=yes] http://repo.pnetlab.com ./" >> /etc/apt/sources.list
#     #     # #     # #  # sudo nano /etc/apt/apt.conf.d/99pnetlab-insecure
#     # 
#     # sudo echo 'Acquire::https::Verify-Peer "false";' | sudo tee /etc/apt/apt.conf.d/99verify-certs.conf
#     # sudo echo 'Acquire::https::Verify-Host "false";' | sudo tee -a /etc/apt/apt.conf.d/99verify-certs.conf
#     # 
#     # echo "nameserver 8.8.8.8" > /etc/resolv.conf
#     # 
#     # apt-get update
#     # 
#     # apt-get purge netplan.io -y   ## Purge packages that GCP relies on especially cloud-init
#     # # #     # #     ## The following packages were automatically installed and are no longer required:
#     # # #     # #     ##   libnetplan0 python3-netifaces
#     # # #     # #     ## Use 'apt autoremove' to remove them.
#     # # #     # #     ## The following packages will be REMOVED:
#     # # #     # #     ##   cloud-init* netplan.io* nplan* ubuntu-minimal*
#     # # # 
#     # sudo DEBIAN_FRONTEND=noninteractive apt-get install pnetlab -y --show-progress
#     # # #     # Installs pnetlab.4.2.10 (v5 will be installed after 4.2.10 is first installed): linux-image-4.15.18-pnetlab2
#     # # #     # "DEBIAN_FRONTEND=noninteractive": tells the Debian package manager (dpkg) to run in non-interactive mode, which automatically chooses the default or least disruptive option for configuration file prompts, in this case, keeping the existing locally modified version. 
# 
# 
# 
# ### repo.pnetlab.com hold the Packages.gz file, which lists the list of required packages and their dependnecies.
# ### it also has the pool/ folder which holds a number of subfolder for various distrbituions and their deb packages.
# ### apt is our package manager. after adding  https://repo.pnetlab.com or  http://repo.pnetlab.com to the sources list with  
# ###     echo "deb [trusted=yes no-all=yes] https://repo.pnetlab.com /" >> /etc/apt/sources.list,
# ###     no-all=yes is to let apt know that is not a conventional apt repo with a number of files that you typically find of those such as /en for english transaltion....
# ###     trusted=yes is to allow accessing the content of the site despite its cert being expired.
# ### to avoid the cert issue we also need to set:
# ###     sudo echo 'Acquire::https::Verify-Peer "false";' | sudo tee /etc/apt/apt.conf.d/99verify-certs.conf
# ###     sudo echo 'Acquire::https::Verify-Host "false";' | sudo tee -a /etc/apt/apt.conf.d/99verify-certs.conf
# ### apt would download Packages.gz to 
# ###     /var/lib/apt/lists
# ### which would tell apt what package to pull when doing an apt install with 
# ###     sudo DEBIAN_FRONTEND=noninteractive apt-get install pnetlab -y --show-progress
# ### Packages woudl be downloaded to:
# ###     /var/cache/apt/archives/
# ### After an install,
# ###     /var/lib/apt/archives/
# ### would contain the unpacked content of the index files (Packages.gz, InRelease, etc.) downloaded by apt update especially the one from pnetlab:
# ###    repo.pnetlab.com_._Packages
# ### it would also contain ubuntu distribution dependencies
#         # # # /var/lib/apt/lists
#         # # # auxfiles
#         # # # esm.ubuntu.com_apps_ubuntu_dists_bionic-apps-security_InRelease
#         # # # esm.ubuntu.com_apps_ubuntu_dists_bionic-apps-security_main_binary-amd64_Packages
#         # # # esm.ubuntu.com_apps_ubuntu_dists_bionic-apps-updates_InRelease
#         # # # esm.ubuntu.com_apps_ubuntu_dists_bionic-apps-updates_main_binary-amd64_Packages
#         # # # esm.ubuntu.com_infra_ubuntu_dists_bionic-infra-security_InRelease
#         # # # esm.ubuntu.com_infra_ubuntu_dists_bionic-infra-security_main_binary-amd64_Packages
#         # # # esm.ubuntu.com_infra_ubuntu_dists_bionic-infra-updates_InRelease
#         # # # esm.ubuntu.com_infra_ubuntu_dists_bionic-infra-updates_main_binary-amd64_Packages
#         # # # lock
#         # # # partial
#         # # # repo.pnetlab.com_._Packages
#         # # # security.ubuntu.com_ubuntu_dists_bionic-security_InRelease
#         # # # security.ubuntu.com_ubuntu_dists_bionic-security_main_binary-amd64_Packages
#         # # # security.ubuntu.com_ubuntu_dists_bionic-security_main_i18n_Translation-en
#         # # # security.ubuntu.com_ubuntu_dists_bionic-security_multiverse_binary-amd64_Packages
#         # # # security.ubuntu.com_ubuntu_dists_bionic-security_multiverse_i18n_Translation-en
#         # # # security.ubuntu.com_ubuntu_dists_bionic-security_restricted_binary-amd64_Packages
#         # # # security.ubuntu.com_ubuntu_dists_bionic-security_restricted_i18n_Translation-en
#         # # # security.ubuntu.com_ubuntu_dists_bionic-security_universe_binary-amd64_Packages
#         # # # security.ubuntu.com_ubuntu_dists_bionic-security_universe_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_InRelease
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_main_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_main_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_universe_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_universe_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_InRelease
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_main_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_main_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_multiverse_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_multiverse_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_restricted_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_restricted_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_universe_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_universe_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_InRelease
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_main_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_main_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_multiverse_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_multiverse_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_restricted_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_restricted_i18n_Translation-en
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_universe_binary-amd64_Packages
#         # # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_universe_i18n_Translation-en
# ### repo.pnetlab.com_._Packages is actually a text file with the content of Packages.gz. It has each package listed in its own paragraph/block such as:
# # # #         # Package: linux-image-4.15.18-pnetlab
# # # #         # Source: linux-source-4.15.18-pnetlab
# # # #         # Version: 4.15.18-pnetlab-10.00.Custom
# # # #         # Architecture: amd64
# # # #         # Maintainer: Unknown Kernel Package Maintainer <unknown@unconfigured.in.etc.kernel-pkg.conf>
# # # #         # Installed-Size: 235717
# # # #         # Pre-Depends: debconf (>= 0.2.17) | debconf-2.0
# # # #         # Depends: coreutils (>= 5.96)
# # # #         # Recommends: initramfs-tools | linux-initramfs-tool, kernel-common
# # # #         # Suggests: fdutils, linux-doc-4.15.18-pnetlab | linux-source-4.15.18-pnetlab, linux-image-4.15.18-pnetlab-dbg, linux-manual-4.15.18-pnetlab
# # # #         # Provides: linux-image, linux-image-4.15, linux-modules-4.15
# # # #         # Filename: ./pool/pnetlab-kernel/linux-image-4.15.18-pnetlab_4.15.18-pnetlab-10.00.Custom_amd64.deb
# # # #         # Size: 53362844
# # # #         # MD5sum: ddb2066542f498d5232b54efc0f6db67
# # # #         # SHA1: ff615b188fb9875b551a391d28b2a85eb95705ca
# # # #         # SHA256: bd6bc3f64182ba44c90b0abc512a7e1ad0f3554aefd5ba75676c66d0c20c8389
# # # #         # Section: kernel
# # # #         # Priority: optional
# # # #         # Description: Linux kernel binary image for version 4.15.18-pnetlab
# # # #         #  This package contains the Linux kernel image for version
# # # #         #  4.15.18-pnetlab.
# # # #         #  .
# # # #         #  It also contains the corresponding System.map file, and the modules
# # # #         #  built by the packager.  It also contains scripts that try to ensure
# # # #         #  that the system is not left in a unbootable state after an update.
# # # #         #  .
# # # #         #  Kernel image packages are generally produced using kernel-package,
# # # #         #  and it is suggested that you install that package if you wish to
# # # #         #  create a custom kernel from the sources. Please look at kernel-img.conf(5),
# # # #         #  and /usr/share/doc/kernel-package/README.gz  from the package kernel-package
# # # #         #  for details on how to tailor the  installation of this or any other kernel
# # # #         #  image package
# 
# ### If we follow the normal process, everything will be downloaded from the remote repo and handled for us however the pentlab repo is super slow. Plus it might disappear at some point in time.
# 
# 
# 
# 
# 
# 
# 
# 
# 
# ### We would like to save what we need for offline installlation of pnetlab: Index files and packages.
#         # Item	          Directory	                                                                             Purpose
#         # Index File	    The decompressed Packages file (or compressed Packages.gz).	                           Tells apt what to install.
#         # PackageFiles	  The full directory containing all .deb files (the pool/ directory and its contents).	 Gives apt the actual files to install.
# 
# ### After a succesful install of pnetlag we saved the packages and the index lists with:
# ### So we will save what we need to buckets.
# ###       gsutil -m cp -r /var/lib/apt/lists/* gs://${local.gcp-project}-bucket-clone/assets-pnetlab/saved-deb-assets/var/lib/apt/lists/
# ###       gsutil -m cp -r /var/cache/apt/archives/* gs://${local.gcp-project}-bucket-clone/assets-pnetlab/saved-deb-assets/var/cache/apt/archives/
# 
# 
# 
# 
# 
# 
# 
# 
# ### There are two methods to then restor and make use of those saved assets to future installs (offline installs):
# # gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/saved-deb-assets/var/lib/apt/lists/* /var/lib/apt/lists/
# # gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/saved-deb-assets/var/cache/apt/archives/* /var/cache/apt/archives/
# 
# ###     Method1: Local Cache restore
# ###       1.1 restore the lists to /var/lib/apt/lists:
# ###           gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/saved-deb-assets/var/lib/apt/lists/* /var/lib/apt/lists/
# ###               this would be either the Packages.gz file or its unzipped content.
# ###               it also contains other dependcies 
# #                         # d
# #                         # # auxfiles
# #                         # # esm.ubuntu.com_apps_ubuntu_dists_bionic-apps-security_InRelease
# #                         # # esm.ubuntu.com_apps_ubuntu_dists_bionic-apps-security_main_binary-amd64_Packages
# #                         # # esm.ubuntu.com_apps_ubuntu_dists_bionic-apps-updates_InRelease
# #                         # # esm.ubuntu.com_apps_ubuntu_dists_bionic-apps-updates_main_binary-amd64_Packages
# #                         # # esm.ubuntu.com_infra_ubuntu_dists_bionic-infra-security_InRelease
# #                         # # esm.ubuntu.com_infra_ubuntu_dists_bionic-infra-security_main_binary-amd64_Packages
# #                         # # esm.ubuntu.com_infra_ubuntu_dists_bionic-infra-updates_InRelease
# #                         # # esm.ubuntu.com_infra_ubuntu_dists_bionic-infra-updates_main_binary-amd64_Packages
# #                         # # lock
# #                         # # partial
# #                         # # repo.pnetlab.com_._Packages
# #                         # # security.ubuntu.com_ubuntu_dists_bionic-security_InRelease
# #                         # # security.ubuntu.com_ubuntu_dists_bionic-security_main_binary-amd64_Packages
# #                         # # security.ubuntu.com_ubuntu_dists_bionic-security_main_i18n_Translation-en
# #                         # # security.ubuntu.com_ubuntu_dists_bionic-security_multiverse_binary-amd64_Packages
# #                         # # security.ubuntu.com_ubuntu_dists_bionic-security_multiverse_i18n_Translation-en
# #                         # # security.ubuntu.com_ubuntu_dists_bionic-security_restricted_binary-amd64_Packages
# #                         # # security.ubuntu.com_ubuntu_dists_bionic-security_restricted_i18n_Translation-en
# #                         # # security.ubuntu.com_ubuntu_dists_bionic-security_universe_binary-amd64_Packages
# #                         # # security.ubuntu.com_ubuntu_dists_bionic-security_universe_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_InRelease
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_main_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_main_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_universe_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-backports_universe_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_InRelease
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_main_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_main_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_multiverse_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_multiverse_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_restricted_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_restricted_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_universe_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic-updates_universe_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_InRelease
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_main_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_main_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_multiverse_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_multiverse_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_restricted_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_restricted_i18n_Translation-en
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_universe_binary-amd64_Packages
# #                         # # us-central1.gce.archive.ubuntu.com_ubuntu_dists_bionic_universe_i18n_Translation-en
# ###       1.2 restore the  actual packages to: /var/cache/apt/archives/
# # #               gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/saved-deb-assets/var/cache/apt/archives/* /var/cache/apt/archives/
# # #
# # #
# # echo "nameserver 8.8.8.8" > /etc/resolv.conf
# # 
# # apt-get purge netplan.io -y   ## Purge packages that GCP relies on especially cloud-init
# # sudo echo 'Acquire::https::Verify-Peer "false";' | sudo tee /etc/apt/apt.conf.d/99verify-certs.conf
# # sudo echo 'Acquire::https::Verify-Host "false";' | sudo tee -a /etc/apt/apt.conf.d/99verify-certs.conf
# 
# # sudo chown -R root:root /var/lib/apt/lists
# # sudo chmod 644 /var/lib/apt/lists/repo.pnetlab.com_._Packages
# # 
# # # Add the local file-based repository line
# #     #This:
# # echo "deb [trusted=yes no-all=yes] https://repo.pnetlab.com /" | sudo tee -a /etc/apt/sources.list
# #     # or: Instead of "echo "deb [trusted=yes no-all=yes] https://repo.pnetlab.com /" | sudo tee -a /etc/apt/sources.list" could have done. 
# #       cd /var/cache/apt/archives/
# #       sudo dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
# #       echo "deb file:///var/cache/apt/archives/ ./" | sudo tee -a /etc/apt/sources.list
# # 
# # sudo apt-get update
# # sudo DEBIAN_FRONTEND=noninteractive apt-get install pnetlab -y --show-progress
# # 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# ###     MEthod2: local repository
# # # 
# # #   # 2.1 Create a local repo and download assets
#           # #   # local-repo/
#           # #   # ├── dists/
#           # #   # │   └── stable/
#           # #   # │       └── main/
#           # #   # │           └── binary-amd64/
#           # #   # │               └── Packages.gz.    ### <-- Packages.gz or content of  /var/lib/apt/lists 
#           # #   # ├── pool/
#           # #   # │   └── main/
#           # #   # │       └── <all .deb files here>.  ### <-- content of /var/cach/apt/archives
# 
# # #       # sudo mkdir -p /local-repo/dists/stable/main/binary-amd64/
# # #       gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/saved-deb-assets/var/lib/apt/lists/* /local-repo/dists/stable/main/binary-amd64/
# # #
# # #       # sudo mkdir -p /local-repo/pool/main
# # #       gsutil -m cp -r gs://${local.gcp-project}-bucket-clone/assets-pnetlab/saved-deb-assets/var/cache/apt/archives/* /local-repo/pool/main
# # #
# # #  # 2.2 
# #       echo "deb [trusted=yes] file:/local-repo stable main" >> /etc/apt/sources.list
# #       echo "nameserver 8.8.8.8" > /etc/resolv.conf
# #       sudo apt-get update
# #       apt-get purge netplan.io -y   ## Purge packages that GCP relies on especially cloud-init
# #       sudo DEBIAN_FRONTEND=noninteractive apt-get install pnetlab -y --show-progress
# 
# 
# 
# 
# 
# 
# 
# # #
# # #
# # #
# # #
# # # reboot
# # # gcloud compute instances tail-serial-port-output vdc-pnetlab-v5
# 
# 
# 
# 
# 
# 
# 
# ####### Second step of pnetlab install.
# 
# 
# 
# #  ctrl-C
# #  sudo -i
# #  ctrl-C
# #  ctrl -l
# #  echo "nameserver 8.8.8.8" > /etc/resolv.conf
# # #     ##curl -sL 'https://labhub.eu.org/api/raw/?path=/UNETLAB%20I/upgrades_pnetlab/bionic/install_pnetlab_latest_v5.sh'| sh
# # #     # # # ##sudo curl -sL 'https://labhub.eu.org/api/raw/?path=/UNETLAB%20I/upgrades_pnetlab/bionic/install_pnetlab_latest_v5.sh'> /root/install_pnetlab_latest_v5.sh
# # #     # # # # if doesn't work we had saved it: 
# # gsutil cp gs://${local.gcp-project}-bucket-clone/pnet-lab-binaries/pnetlab-v5-latest/install_pnetlab_latest_v5.sh ./
# # sed -i.bak 's|path=/UNETLAB%20I/upgrades_pnetlab|path=/upgrades_pnetlab|g' install_pnetlab_latest_v5.sh
#### Path to zip should be: URL_PNET_PNETLAB=https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/bionic/stable/5.3.13.zip
# # . ./install_pnetlab_latest_v5.sh
# # #   # # # gsutil -m cp -r /root/install_pnetlab_latest_v5.sh gs://vdc-tf-bucket/pnet-lab-binaries/pnetlab-v5-latest/
# # # 
# # # ##ishare2 github: https://github.com/pnetlabrepo/ishare2
# # #     # # #sudo wget -O /usr/sbin/ishare2 https://raw.githubusercontent.com/pnetlabrepo/ishare2/main/ishare2 > /dev/null 2>&1 
# # # sudo wget -O /usr/sbin/ishare2 https://raw.githubusercontent.com/ishare2-org/ishare2-cli/main/ishare2 > /dev/null 2>&1 
# # # sudo chmod +x /usr/sbin/ishare2
# # # 
# # # 
# # sudo sed -i '/if \[ -d \/etc\/profile.d \];/i\ if \[ -f \/etc\/bashrc \];\n\ . \/etc\/bashrc\n\ fi' /etc/profile
# # # # #         #--> syntax error of above command (extra space before the inserted if statement) actually is useful for forcing a skip of the pnet setup window that we use to have to ctrl-c from.
# # # # # 
# # sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /etc/bash.bashrc
# # # 
# # 
# # 
# # ### END OF: Interactive/manual pnet server configuration instructions
# # ########################################################################################################################################################################
# # ########################################################################################################################################################################
# # 
# # 
# # 
# # 
# # 
# # 
# # 
# # # # # # ## Note to self: look into qemu-utils (is being installed)
# # # # # # ###OR, if wanted to automate installation of pnetlab: problem is that at some point installation requires user input (kernel update) so not an option to automate the installation:
# # # # # # ##   # Automation of pnetlab installation (v5): will take about 15 minutes
# # # # # # ##   metadata = {
# # # # # # ##     enable-oslogin     = "true"
# # # # # # ##     serial-port-enable = "true"
# # # # # # ##     user-data = data.template_file.cloud_init_config_v5.rendered
# # # # # # ##     block-project-ssh-keys = "false"
# # # # # # ##   }
# # # # # # ##
# # # # # # ## }
# # # # # # ## data "template_file" "cloud_init_config_v5" {
# # # # # # ##   template = file("./cloud-init-pnet-v5.yaml")
# # # # # # ## }
# # 
# # 
# # 
# # 
# # 
# # 
# # 
# # ############## ---- Generate vdc-pnetlab-v5-image-base from above instance. We will then export that image to a cloud bucket as vmdk (a bucket that will be cloned by lab consumers)
# # # 
# # ##### Now that we installed pnetlab (manually) Create 'pnetlab_v5_custom_base' custom image for pnetlab-v5 fully setup (no need to when have above vmdk shared to users)
# 
# 
# ##Stop instance first
# #gcloud compute instances stop vdc-pnetlab-v5-2 --zone=us-central1-a
# #
# ## via gcloud:
# #gcloud compute images create vdc-pnetlab-v5-image-base --source-disk=vdc-pnetlab-v5 --source-disk-zone=us-central1-a --family=vdc-pnetlab-images --project=vdc-tf2 --description="Export from vdc-pnetlab-v5 (pnetlab installed) from vdc_tf"
# #
# ## via tf:
# #resource "google_compute_image" "pnetlab_v5_image_base" {
# #  name              = "vdc-pnetlab-v5-image-base"
# #  project           = local.gcp-project # Replace with your project ID
# #  storage_locations = ["${local.gcp-region}"]
# #  source_disk       = google_compute_instance.vdc_pnetlab_v5.boot_disk[0].source
# #  # Optional settings
# #  family      = "vdc-pnetlab-images"
# #  description = "Image of installed pnetlab-v5 server (i.e. without linux networking customizations. check echo nameserver 8.8.8.8 > /etc/resolv.conf as well )"
# #  licenses    = ["https://www.googleapis.com/compute/v1/projects/ubuntu-os-pro-cloud/global/licenses/ubuntu-pro-1804-lts", "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"]
# #  depends_on  = [null_resource.stop_instance, google_compute_instance.vdc_pnetlab_v5]
# #  lifecycle {
# #    prevent_destroy = true
# #  }
# #}
# 
# 
# #gcloud compute images create vdc-pnetlab-v5-2-replica --source-disk=vdc-pnetlab-v5-2 --source-disk-zone=us-central1-a --family=vdc-pnetlab-images --project=vdc-tf --description="Export from vdc-pnetlab-v5-2 (image of vdc-pnetlab-v5 export and lab topo imported but not clean) from vdc_tf"
# 
# ## or tf
# #resource "google_compute_image" "pnetlab_v5_image_base" {
# #  name              = "vdc-pnetlab-v5-image-base"
# #  project           = local.gcp-project # Replace with your project ID
# #  storage_locations = ["${local.gcp-region}"]
# #  source_disk       = google_compute_instance.vdc_pnetlab_v5.boot_disk[0].source
# #  # Optional settings
# #  family      = "vdc-pnetlab-images"
# #  description = "Image of installed pnetlab-v5 server (i.e. without linux networking customizations. check echo nameserver 8.8.8.8 > /etc/resolv.conf as well )"
# #  licenses    = ["https://www.googleapis.com/compute/v1/projects/ubuntu-os-pro-cloud/global/licenses/ubuntu-pro-1804-lts", "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"]
# #  depends_on  = [null_resource.stop_instance, google_compute_instance.vdc_pnetlab_v5]
# #  lifecycle {
# #    prevent_destroy = true
# #  }
# #}
# 
# #
# #  
# # 
# #### export as raw disk from copmute image so that can use in the future for import to a cmpute image
# #
# # gcloud compute images export \
# #   --destination-uri=gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-image-base.tar.gz \
# #   --image=vdc-pnetlab-v5-image-base \
# #   --project=vdc-tf2
# 
# ## DESTINATION="gs://vdc-tf-bucket/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-2-replica.tar.gz"
# ## IMAGE=vdc-pnetlab-v5-2-replica
# ## PROJECT=vdc-tf
# ## gcloud compute images export --destination-uri=$DESTINATION --image=$IMAGE --project=$PROJECT
# 
# #
# #### in the future, can download the disk to an image using:
# # 
# # gcloud compute images create vdc-pnetlab-v5-image-base-imported \
# # --source-uri="gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-image-base.tar.gz" \
# # --project=vdc-tf2 \
# # --family=vdc-pnetlab-images \
# # --guest-os-features=UEFI_COMPATIBLE \
# # --licenses="https://www.googleapis.com/compute/v1/projects/ubuntu-os-pro-cloud/global/licenses/ubuntu-pro-1804-lts","https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"
# 
# # # 
# # # 
# # # 
# # # 
# # # 
# # #  
# # #  
# # #  
# # # 
# # # ### Download the vmdk from bucket so that we can prep it for future use as a compute image directly obtinaed from cloud bucket
# # # # gsutil cp gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-image-base-v3.vmdk ./
# # # # tar -cvf pnetlab-v5-image-base-v3.vmdk.tar pnetlab-v5-image-base-v3.vmdk
# # # # gzip pnetlab-v5-image-base-v3.vmdk.tar
# # # # gsutil cp netlab-v5-image-base-v3.vmdk.tar.gz  gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/
# # # 
# # # resource "google_compute_image" "pnetlab_v5_image_base_v3" {
# # #   name = "vdc-pnetlab-v5-image-base-v3"
# # # 
# # #   raw_disk {
# # #     source = "gs://${google_storage_bucket.project_bucket.name}/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-image-base-v3.vmdk.tar.gz"
# # #   }
# # # }
# # # # 
# # # # and reference it with
# # #   # boot_disk {
# # #   #   initialize_params {
# # #   #     # Reference the image by its name from the previous resource block
# # #   #     image = google_compute_image.pnetlab_v5_image_base_v3.name
# # #   #   }
# # #   # }
# # # 
# # # 
# # # 
# # # 
# 
# 
# 
# 
# 

















































































#10-PNET-LAB-From-Image-that-has-pnetlab-installed
# !!! you cannot have two pnet appliance running at once and using the same alias iprange. This impacts internet  connectivity of the CE router appliance as they use the 10.10.25.0/24 cidr 
# if want both would need to change the network of the uplink so that i leverages the new alias ip range of eth1 (which allows cloudNAT to the internet)
#################################################################################################################################################################
#################################################################################################################################################################
################# Create pnet-lab instance from the imported assets (vmdk/gce image) ############################################################################
#################################################################################################################################################################
#################################################################################################################################################################
#
# terraform apply -replace=google_compute_instance.vdc_pnetlab_v5_2
# terraform apply -replace google_compute_instance.vdc_pnetlab_v5_2
#
#
#gcloud compute images create vdc-pnetlab-v5-lab-configured --source-disk=vdc-pnetlab-v5-2 --source-disk-zone=us-central1-a --family=vdc-pnetlab-images --project=vdc-tf2 --description="Export from vdc-pnetlab-v5-2 (lab topo configured)"
#
#
#
#
#-> now done in main.sh
# # manually run once
# gcloud compute images create vdc-pnetlab-v5-bucket-imported \
# --source-uri="gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-image-base.tar.gz" \
# --project=vdc-tf2 \
# --family=vdc-pnetlab-images \
# --guest-os-features=UEFI_COMPATIBLE \
# --description="Base image: gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-image-base.tar.gz" \
# --licenses="https://www.googleapis.com/compute/v1/projects/ubuntu-os-pro-cloud/global/licenses/ubuntu-pro-1804-lts","https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"
## OR
# gcloud compute images create vdc-pnetlab-v5-bucket-imported \
# --source-uri="gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-lab-configured.tar.gz" \
# --project=vdc-tf2 \
# --family=vdc-pnetlab-images \
# --guest-os-features=UEFI_COMPATIBLE \
# --description="Configured image: gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-lab-configured.tar.gz" \
# --licenses="https://www.googleapis.com/compute/v1/projects/ubuntu-os-pro-cloud/global/licenses/ubuntu-pro-1804-lts","https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"
#


data "google_compute_image" "imported_image" {
  name    = "vdc-pnetlab-v5-imported"
  project = local.gcp-project
}






resource "google_compute_instance" "vdc_pnetlab_v5" {
  deletion_protection = false

  machine_type = "n2-highmem-8"
  name         = var.pnetlab_server_name
  zone         = local.gcp-zone

  boot_disk {
    initialize_params {
      # Reference the image by its name from the previous resource block
      image = data.google_compute_image.imported_image.self_link
    }
  }


  can_ip_forward = true
  enable_display = true

  network_interface {
    nic_type    = "VIRTIO_NET"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.vdc_vpc1_net_10.self_link
    network_ip  = "10.10.10.216"
    alias_ip_range {
      ip_cidr_range         = "10.10.15.0/24"
      subnetwork_range_name = "secondary-vpc1-net-10-15"
    }
  }

  network_interface {
    nic_type    = "VIRTIO_NET"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.vdc_vpc2_net_20.self_link
    network_ip  = "10.10.20.216"
    alias_ip_range {
      ip_cidr_range         = "10.10.25.0/24"
      subnetwork_range_name = "secondary-vpc2-net-20-25"
    }
  }

  network_interface {
    nic_type    = "VIRTIO_NET"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.vdc_vpc3_net_30.self_link
    network_ip  = "10.10.30.216"
    alias_ip_range {
      ip_cidr_range         = "10.10.35.0/24"
      subnetwork_range_name = "secondary-vpc3-net-30-35"
    }

  }

  network_interface {
    nic_type    = "VIRTIO_NET"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.vdc_vpc4_net_40.self_link
    network_ip  = "10.10.40.216"
    alias_ip_range {
      ip_cidr_range         = "10.10.45.0/24"
      subnetwork_range_name = "secondary-vpc4-net-40-45"
    }
  }

  network_interface {
    nic_type    = "VIRTIO_NET"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.vdc_vpc5_net_50.self_link
    network_ip  = "10.10.50.216"
    alias_ip_range {
      ip_cidr_range         = "10.10.55.0/24"
      subnetwork_range_name = "secondary-vpc5-net-50-55"
    }
  }

  network_interface {
    nic_type    = "VIRTIO_NET"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.vdc_vpc6_net_60.self_link
    network_ip  = "10.10.60.216"
    alias_ip_range {
      ip_cidr_range         = "10.10.65.0/24"
      subnetwork_range_name = "secondary-vpc6-net-60-65"
    }
  }

  network_interface {
    nic_type    = "VIRTIO_NET"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.vdc_vpc7_net_70.self_link
    network_ip  = "10.10.70.216"
    alias_ip_range {
      ip_cidr_range         = "10.10.75.0/24"
      subnetwork_range_name = "secondary-vpc7-net-70-75"
    }
    access_config {
      network_tier = "PREMIUM"
    }
  }

  network_interface {
    nic_type    = "VIRTIO_NET"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.vdc_vpc8_net_80.self_link
    network_ip  = "10.10.80.216"
    alias_ip_range {
      ip_cidr_range         = "10.10.85.0/24"
      subnetwork_range_name = "secondary-vpc8-net-80-85"
    }
    access_config {
      network_tier = "PREMIUM"
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  # Attach instance scheduling policies
  resource_policies = compact(concat(
    var.enable_auto_shutdown ? (length(google_compute_resource_policy.instance_shutdown_schedule) > 0 ? [google_compute_resource_policy.instance_shutdown_schedule[0].id] : []) : [],
    var.enable_auto_startup ? (length(google_compute_resource_policy.instance_startup_schedule) > 0 ? [google_compute_resource_policy.instance_startup_schedule[0].id] : []) : []
  ))

  service_account {
    email  = local.gce-sa
    scopes = ["https://www.googleapis.com/auth/devstorage.read_write", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    # made cloud storage api read_write vs read_only in case we want to write to the bucket via the SA.
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  depends_on = [
    google_org_policy_policy.compute_requireShieldedVm,
    google_org_policy_policy.compute_vmCanIpForward,
    google_org_policy_policy.compute_vmExternalIpAccess,
    google_org_policy_policy.compute_disableSerialPortAccess,
    google_org_policy_policy.compute_requireOsLogin,
    google_org_policy_policy.compute_disableNestedVirtualization,
    google_org_policy_policy.allow_compute_image_import,
    google_compute_subnetwork.vdc_vpc1_net_10,
    google_compute_subnetwork.vdc_vpc2_net_20,
    google_compute_subnetwork.vdc_vpc3_net_30,
    google_compute_subnetwork.vdc_vpc4_net_40,
    google_compute_subnetwork.vdc_vpc5_net_50,
    google_compute_subnetwork.vdc_vpc6_net_60,
    google_compute_subnetwork.vdc_vpc7_net_70,
    google_compute_subnetwork.vdc_vpc8_net_80,
    #data.external.validate_compute_policies,
  ]

  metadata = {
    enable-oslogin     = "true"
    serial-port-enable = "true"
    startup-script     = <<EOF
      #!/bin/bash

      # Setup logging
      LOG_FILE="/var/log/pnetlab-startup.log"
      exec > >(tee -a "$LOG_FILE") 2>&1

      echo "=========================================="
      echo "PNetLab Startup Script - $(date)"
      echo "Project: ${var.gcp_project}"
      echo "=========================================="

      # Ensure gcloud uses the instance's attached service account
      echo "Configuring gcloud to use instance service account..."
      gcloud config set account ${local.gce-sa}
      echo "Active gcloud account: $(gcloud config get-value account)"

      #sudo apt-get purge netplan.io -y

      #  sudo sed -i '/if \[ -d \/etc\/profile.d \];/i\
      #  if \[ -f \/etc\/bashrc \];\n\
      #  . \/etc\/bashrc\n\
      #  fi' /etc/profile
      #  sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /root/.bashrc

      # Marker file to track if first-time setup is complete
      SETUP_MARKER="/var/lib/pnetlab-first-setup-complete"

      # Commands that should run every boot
      echo "Setting DNS resolver..."
      echo "nameserver 8.8.8.8" > /etc/resolv.conf

      # Check if this is the first boot
      if [ ! -f "$SETUP_MARKER" ]; then
          echo "First boot detected - running initial setup..."
          
          # First-time setup commands here
          echo "Configuring bash profile..."
          sudo sed -i '/if \[ -d \/etc\/profile.d \];/i\ if \[ -f \/etc\/bashrc \];\n\ . \/etc\/bashrc\n\ fi' /etc/profile
          sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /etc/bash.bashrc
          
          # SSH key operations
          echo "Starting SSH key operations..."
          echo "Checking for existing SSH key folder in bucket..."
          
          if gsutil ls "gs://${var.gcp_project}-bucket-clone/assets-pnetlab/pnetserver-sshkey/" 2>/dev/null | grep -q "gs://${var.gcp_project}-bucket-clone/assets-pnetlab/pnetserver-sshkey/"; then
              echo "🗑️ Folder found at gs://${var.gcp_project}-bucket-clone/assets-pnetlab/pnetserver-sshkey/. Proceeding with deletion..."
              # The -r flag is correct for deleting a directory and its contents
              sudo gsutil rm -r "gs://${var.gcp_project}-bucket-clone/assets-pnetlab/pnetserver-sshkey/"
              
              if [ $? -eq 0 ]; then
                  echo "✅ Folder deleted successfully."
              else
                  echo "❌ Error during gsutil rm command. Exit code: $?"
              fi
          else
              echo "⏭️ Folder not found at gs://${var.gcp_project}-bucket-clone/assets-pnetlab/pnetserver-sshkey/. Skipping deletion."
          fi
          
          echo "Removing any existing SSH keys from /root/.ssh/..."
          sudo rm -f /root/.ssh/id_rsa
          sudo rm -f /root/.ssh/id_rsa.pub

          echo "Generating new SSH key pair..."
          sudo ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
          
          if [ $? -eq 0 ]; then
              echo "✅ SSH key generation successful"
              echo "Private key file size: $(ls -la /root/.ssh/id_rsa)"
              echo "Public key file size: $(ls -la /root/.ssh/id_rsa.pub)"
          else
              echo "❌ SSH key generation failed. Exit code: $?"
              exit 1
          fi
          
          echo "Uploading private key to bucket..."
          sudo gsutil cp /root/.ssh/id_rsa gs://${var.gcp_project}-bucket-clone/assets-pnetlab/pnetserver-sshkey/
          PRIVATE_KEY_UPLOAD_STATUS=$?
          
          echo "Uploading public key to bucket..."
          sudo gsutil cp /root/.ssh/id_rsa.pub gs://${var.gcp_project}-bucket-clone/assets-pnetlab/pnetserver-sshkey/
          PUBLIC_KEY_UPLOAD_STATUS=$?
          
          if [ $PRIVATE_KEY_UPLOAD_STATUS -eq 0 ] && [ $PUBLIC_KEY_UPLOAD_STATUS -eq 0 ]; then
              echo "✅ SSH keys generated and uploaded to bucket successfully"
              echo "Verifying upload by listing bucket contents..."
              gsutil ls -la gs://${var.gcp_project}-bucket-clone/assets-pnetlab/pnetserver-sshkey/
              
              # Add the public key to authorized_keys for incoming SSH connections
              echo "Setting up authorized_keys for SSH access..."
              mkdir -p /root/.ssh
              chmod 700 /root/.ssh
              cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
              chmod 600 /root/.ssh/authorized_keys
              echo "✅ Public key added to authorized_keys - pnet server can now accept SSH connections"
          else
              echo "❌ SSH key upload failed. Private key status: $PRIVATE_KEY_UPLOAD_STATUS, Public key status: $PUBLIC_KEY_UPLOAD_STATUS"
              echo "Checking service account permissions..."
              gsutil iam get gs://${var.gcp_project}-bucket-clone
              exit 1
          fi
          
          # File operations
          sudo cp /root/routes-fix-all-final.sh.dualhomed /root/routes-fix-all-final.sh
          sudo chmod +x /root/routes-fix-all-final.sh


          ## image has those baked in.          
          # Asset moving operations
          #sudo mkdir /downloads
          # sudo gsutil -m cp -r gs://${"google_storage_bucket.project_bucket.name"}/assets-pnetlab/vyos-configs/ /downloads/

          ## image has those baked in.
          # sudo mkdir -p /downloads/opt/unetlab/labs
          # sudo gsutil cp -r gs://${"google_storage_bucket.project_bucket.name"}/assets-pnetlab/opt/unetlab/ /downloads/opt/          
          # sudo gsutil cp -r gs://${"google_storage_bucket.project_bucket.name"}/assets-pnetlab/opt/unetlab/labs/vdc-leaf-spine-L3.unl /downloads/opt/unetlab/labs/

          ## image has those baked in.
          # sudo mv /downloads/opt/unetlab/addons/qemu/* /opt/unetlab/addons/qemu/
          # sudo mv /downloads/opt/unetlab/html/images/icons/* /opt/unetlab/html/images/icons/
          # sudo cp /downloads/opt/unetlab/labs/vdc-leaf-spine-L3.unl /opt/unetlab/labs/
          # sudo /opt/unetlab/wrappers/unl_wrapper -a fixpermissions
          
          # Create marker file to indicate setup is complete
          touch "$SETUP_MARKER"
          echo "First-time setup completed"
      else
          echo "Subsequent boot detected - skipping first-time setup"
      fi

      # Commands that should run every boot
      sudo /root/routes-fix-all-final.sh
      
    EOF
  }
}





# Monitor deployment:
# gcloud compute instances tail-serial-port-output vdc-pnetlab-v5-2 | grep -E '^|startup-script'
# gcloud compute scp --tunnel-through-iap ./routes-fix-all-final.sh.singlehomed vdc-pnetlab-v5:~/tmp
# gcloud compute ssh --tunnel-through-iap vdc-pnetlab-v5






## Export image to gce image and then to bucket .tar.gz (for future imports)
#
# gcloud compute images create vdc-pnetlab-v5-sme-aca-v4 --source-disk=vdc-pnetlab-v5-2 --source-disk-zone=us-central1-c --family=vdc-pnetlab-images --project=vdc-09289 --description=" SME Academy version v4 leaf-spine only with servers"
# with sshguard disabled:, baked from vdc-pnetlab-v5-sme-aca-v4 as base + vyos CE-A name set + yellow cloud for first node to start:
# gcloud compute images create vdc-pnetlab-v5-sme-aca-v6 --source-disk=vdc-pnetlab-v5-2 --source-disk-zone=us-central1-b --family=vdc-pnetlab-images --project=vdc-01307 --description=" from SME Academy version v4 with sshduard disabled and vyos ce-name and yellow cloud"
#
# Built on top of v7 but had to recreate Core-A and fix permissions. 
# gcloud compute images create vdc-pnetlab-v5-sme-aca-v8 --source-disk=vdc-pnetlab-v5-2 --source-disk-zone=us-central1-c --family=vdc-pnetlab-images --project=vdc-09289 --description=" from SME Academy version v7 with Core-A rebuilt & fix permissions"

# v8 but had forgotten to edit routes-fix-all-final.sh.dualhomed to disable ssh guard it it was to popup. In this new image we are creating, sshguard was uninstalled as well
# gcloud compute images create vdc-pnetlab-v5-sme-aca-v9 --source-disk=vdc-pnetlab-v5-2 --source-disk-zone=us-central1-c --family=vdc-pnetlab-images --project=vdc-09289 --description=" from SME Academy version v8, no sshguard "

# v9 Had forgottend to delte the /var/lib/pnet marker that prevented ssh keys to be created and copied to bucket on first boot
# gcloud compute images create vdc-pnetlab-v5-sme-aca-v10 --source-disk=vdc-pnetlab-v5-2 --source-disk-zone=us-central1-c --family=vdc-pnetlab-images --project=vdc-09289 --description=" from SME Academy version v9, no marker "


## export as raw disk from copmute image so that can use in the future for import to a cmpute image
# EXP_DESTINATION="gs://vdc-09289-bucket-clone/assets-pnetlab/custom-images/pnetlab/vdc-pnetlab-v5-sme-aca-v10.tar.gz"
# EXP_IMAGE="vdc-pnetlab-v5-sme-aca-v10"
# EXP_PROJECT="vdc-09289"
# gcloud compute images export --destination-uri=$EXP_DESTINATION --image=$EXP_IMAGE --project=$EXP_PROJECT
#
## Make sure to copy from our bucket to the assets bucket vdc-tf-bucket (is the bucket being clones on new lab deployments via tf)
# gsutil cp gs://${EXP_PROJECT}-bucket-clone/assets-pnetlab/custom-images/pnetlab/${EXP_IMAGE}.tar.gz gs://vdc-tf-bucket/assets-pnetlab/custom-images/pnetlab/




# ### in the future, can download the disk to an image using (handled by main.sh)
#
# gcloud compute images create vdc-pnetlab-v5-image-base-imported \
# --source-uri="gs://vdc-02948-bucket-clone/custom-images/pnetlab/vdc-pnetlab-v5-sme-aca-v4.tar.gz" \
# --project=vdc-XXXX \
# --family=vdc-pnetlab-images \
# --guest-os-features=UEFI_COMPATIBLE \
# --licenses="https://www.googleapis.com/compute/v1/projects/ubuntu-os-pro-cloud/global/licenses/ubuntu-pro-1804-lts","https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"









































# Output the pnetlab server name for use by servers/tf terraform script
output "pnetlab_server_name" {
  description = "The name of the PNet Lab server instance"
  value       = var.pnetlab_server_name
}

# Output the storage bucket name for use by servers/tf terraform script
# Bucket is created by main.sh with pattern: vdc-${RANDOM_SUFFIX}-bucket-clone
# We can reconstruct this from the project ID which follows pattern: vdc-${RANDOM_SUFFIX}
output "storage_bucket_name" {
  description = "The name of the storage bucket containing SSH keys and assets"
  value       = "${local.gcp-project}-bucket-clone"
}



## Access via jump host (for other tools like mremoteng too ssh to the switches) or via:
## gcloud compute ssh root@vdc-pnetlab-v5-2 --tunnel-through-iap -- -L 8080:10.10.10.216:443
## https://https://localhost:8080


























# #################################################################################################################################################################
################# Instance Scheduling - Automatic Shutdown/Startup ############################################################################################
# #################################################################################################################################################################

# Resource policy for automatic instance shutdown (only if enabled)
resource "google_compute_resource_policy" "instance_shutdown_schedule" {
  count  = var.enable_auto_shutdown ? 1 : 0
  name   = "shutdown-${var.auto_shutdown_time}00-${replace(lower(var.instance_timezone), "/", "-")}"
  region = local.gcp-region
  
  instance_schedule_policy {
    vm_stop_schedule {
      schedule = "0 ${var.auto_shutdown_time} * * *"  # Daily at specified hour
    }
    time_zone = var.instance_timezone
  }
  
  description = "Automatically stop instances at ${var.auto_shutdown_time}:00 ${var.instance_timezone}"
  
  lifecycle {
    create_before_destroy = true
  }
}

# Optional: Resource policy for automatic instance startup (only if enabled)
resource "google_compute_resource_policy" "instance_startup_schedule" {
  count  = var.enable_auto_startup ? 1 : 0
  name   = "startup-${var.auto_startup_time}00-${replace(lower(var.instance_timezone), "/", "-")}"
  region = local.gcp-region
  
  instance_schedule_policy {
    vm_start_schedule {
      schedule = "0 ${var.auto_startup_time} * * 1-5"  # Weekdays at specified hour
    }
    time_zone = var.instance_timezone
  }
  
  description = "Automatically start instances at ${var.auto_startup_time}:00 ${var.instance_timezone} on weekdays"
}

#################################################################################################################################################################
################# Outputs for Remote State Access ############################################################################################################
#################################################################################################################################################################

# Output the GCP project ID for use by child configurations (e.g., servers/tf)
output "gcp_project" {
  description = "The GCP project ID"
  value       = local.gcp-project
}

# Output the GCP zone for use by child configurations (e.g., servers/tf)
output "gcp_zone" {
  description = "The GCP zone"
  value       = local.gcp-zone
}

# Output the GCP region for use by child configurations (e.g., servers/tf)
output "gcp_region" {
  description = "The GCP region"
  value       = local.gcp-region
}

# Output the GCP project number for use by child configurations (e.g., servers/tf)
output "gcp_project_number" {
  description = "The GCP project number"
  value       = local.gcp-project-number
}

# Output the user account for use by child configurations (e.g., servers/tf)
output "user_account" {
  description = "The user account"
  value       = local.user-account
}

output "svc_account" {
  description = "The service account"
  value       = local.svc-account
}

output "billing_account_id" {
  description = "The billing account ID used by the VDC project"
  value       = local.billing_account_id
}

output "gcp_project_folder_id" {
  description = "The GCP project parent folder ID"
  value       = local.gcp-project-folder-id
}
