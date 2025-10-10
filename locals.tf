# Local values for the VDC project
locals {
  # Read billing account ID from file
  billing_account_id = fileexists(".billing_id") ? trimspace(file(".billing_id")) : ""
  
  # Other local values from main.tf
  gcp-orgid= "${var.gcp_orgid}"
  gcp-project = "${var.gcp_project}"
  gcp-region = "${var.gcp_region}"
  gcp-zone = "${var.gcp_zone}"
  gcp-project-number = "${var.gcp_project_number}"
  gcp-project-folder-id = "${var.gcp_project_folder_id}"
  user-account = "${var.user_account}"
  svc-account = "${var.svc_account}"
  path-module = "${var.path_module}"
  gce-sa-eve-ng-368801 = "${var.gce_sa_eve_ng_368801}"

  gce-sa = "${var.gcp_project_number}-compute@developer.gserviceaccount.com"
  cloudbuild-sa = "${var.gcp_project_number}@cloudbuild.gserviceaccount.com"
  storagetransfer-sa = "project-${var.gcp_project_number}@storage-transfer-service.iam.gserviceaccount.com"
  
  # add gce service account from ng-project that deploy containerlab (during tests) so that it can pull assets from the storage bucket from this project
  
  # Convert pnetlab server name from dashes to underscores for resource name
  pnetlab_server_resource_name = replace(var.pnetlab_server_name, "-", "_")

  cloudbuild_sa_roles = toset([
    "roles/compute.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/compute.networkUser",
    "roles/cloudbuild.builds.builder",
  ])

  gce_sa_roles = toset([
    "roles/compute.admin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser",
    "roles/compute.networkUser",
    "roles/cloudbuild.builds.builder",
    "roles/compute.storageAdmin",
    "roles/storage.objectAdmin",
    "roles/storage.admin",
    "roles/storage.objectViewer",
  ])
}
