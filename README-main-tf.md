
Not everything could be done in terraform and using the local-exec provider to run gcloud or gstuil command is not ideal.
therefore one needs to use main.sh first and then main.tf.

This specific repo is made for the lab admin/builder as a lab user would be leveraging a pnetlab image of pnet v5 already ready to go for use.
There will be another repo for lab users. 

# Terraform PNetLab on GCP - `main.tf` Explained

## Git clone:
git clone git@gitlab.com:ymeillier/vDC-tf.git

## Change to new remote repo
<!-- git remote add origin https://gitlab.com/ymeillier/vdc-tf2.git
git branch -M main
git push -uf origin main -->

git remote set-url origin ssh://git@gitlab.com/ymeillier/vDC-tf.git
git push -u origin main:feature-branch

## Overview

The primary goal of this Terraform configuration is to automate the deployment of a complex networking lab environment on Google Cloud Platform (GCP) using PNetLab, a network emulation software. It creates all the necessary GCP infrastructure, including networking, virtual machines, custom images, and a Windows jump host for easy access. The configuration is designed to be a self-contained, distributable lab environment.

Here is a step-by-step explanation of the components:

### Step 1: Terraform and Provider Configuration

This section declares the necessary Terraform providers for this project (e.g., `hashicorp/google`, `hashicorp/null`) and pins them to specific versions to ensure consistent behavior. It also configures the Google Cloud provider with the project ID and region where the resources will be deployed. The `locals {}` block is crucial for maintainability, defining variables like project ID, region, and service accounts in one place for easy reuse and modification.

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.14.1"
    }
    # ... other providers
  }
}

provider "google" {
  # Configuration options
  project = local.gcp-project
  region  = local.gcp-region
}

locals {
  gcp-project = "vdc-tf"
  gcp-region  = "us-central1"
  # ... other local variables
}
```



### Step 2: Enabling Google Cloud APIs

Before you can use a Google Cloud service (like Compute Engine or Cloud Storage), its API must be enabled for your project. This block of `google_project_service` resources handles this automatically. It ensures that all required APIs (Compute Engine, Cloud Build, Storage, IAM, etc.) are enabled before Terraform attempts to create resources that depend on them.

```shell
# Enable APIs
resource "google_project_service" "cloudresourcemanager_googleapis_com" {
  project            = local.gcp-project
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false # Set to true to disable on destroy
}
# ... other google_project_service resources ...
```

### Step 3: Granting IAM Permissions

This section manages Identity and Access Management (IAM) roles. It grants specific permissions to service accounts and users. For example, it gives the Cloud Build service account roles like `compute.admin` and `storage.admin` so it can perform tasks during automated image exports. It also grants permissions to the default Compute Engine service account and the specified user account to manage resources.

```shell
# IAM Roles and Permissions
resource "google_project_iam_member" "compute_admin_cloudbuild_sa" {
  project = local.gcp-project # Your project ID
  role    = "roles/compute.admin"
  member  = "serviceAccount:${local.cloudbuild-sa}"
}
# ... other google_project_iam_member resources ...
```

### Step 4: Configuring Organization Policies

This part customizes organization policies at the project level. For a flexible lab environment, certain security constraints are relaxed to allow for nested virtualization, IP forwarding, and traditional SSH key-based access, which are essential for running PNetLab.

```shell
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
# ... other google_org_policy_policy resources ...
```

### Step 5: Building the Network Foundation (VPCs & Subnets)

This is the core of the networking setup. It creates eight separate Virtual Private Clouds (VPCs) and a very large number of subnets within them. The code cleverly uses the `for_each` meta-argument with `locals` maps to create dozens of subnets without repeating the resource block for each one. The IP addressing scheme is designed to mimic a physical data center layout, making the virtual lab feel more realistic.

```shell
# VPC Networks
resource "google_compute_network" "vdc_vpc1" {
  auto_create_subnetworks = false
  mtu                     = 8896
  name                    = "vdc-vpc1"
  # ...
}

# Subnetworks for each VPC 
locals {
  subnets-vpc1-rs = {
    "90" = "10.10.90.0/24",
    # ...
  }
}
resource "google_compute_subnetwork" "vdc_vpc1_net_rs" {
  for_each = local.subnets-vpc1-rs
  # ...
}
```

### Step 6: Firewall Rules

For simplicity in a lab environment, this section creates very permissive firewall rules that allow all incoming and outgoing traffic. **This is not secure and should never be done in a production environment.**

```shell
# FIREWALL
resource "google_compute_firewall" "ingress_all_vpc1" {
  allow {
    protocol = "all"
  }
  direction     = "INGRESS"
  name          = "ingress-all-vpc1"
  network       = google_compute_network.vdc_vpc1.id
  source_ranges = ["0.0.0.0/0"]
}
```

### Step 7: Providing Internet Access (Cloud NAT)

This creates Cloud Routers and attaches Cloud NAT gateways to them in several VPCs. This allows virtual machines within those private subnets to initiate outbound connections to the internet (e.g., for software updates) without having their own public IP addresses.

```shell
resource "google_compute_router" "vdc_vpc1_cloud_router" {
  name    = "vdc-vpc1-cloud-router"
  network = google_compute_network.vdc_vpc1.id
  # ...
}

resource "google_compute_router_nat" "vdc_vpc1_nat" {
  name                               = "vdc-vpc1-nat"
  router                             = google_compute_router.vdc_vpc1_cloud_router.name
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  # ...
}
```

### Step 8: Preparing PNetLab Base Images

PNetLab requires nested virtualization. This section prepares a base GCE image with it enabled. It takes a standard Ubuntu 18.04 image, creates a persistent disk from it, and then creates a *new* custom image from that disk, attaching the special `enable-vmx` license. This `ubuntu-bionic-nested` image is then used as the base for the PNetLab VM.

```terraform
data "google_compute_image" "ubuntu_1804_lts" {
  name    = "ubuntu-pro-1804-bionic-v20241217"
  project = "ubuntu-os-pro-cloud"
}

resource "google_compute_image" "ubuntu_bionic_nested" {
  name        = "ubuntu-bionic-nested"
  source_disk = google_compute_disk.persistent_disk_1804lts.self_link
  licenses    = ["...", "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"]
}
```

### Step 9: Staging Assets in Cloud Storage

This creates a Google Cloud Storage (GCS) bucket to act as a repository for all the files needed to set up the lab. It then uploads several assets, such as shell scripts and custom icons for PNetLab, to this bucket. The PNetLab VM will later download these files during its startup process.

```terraform
resource "google_storage_bucket" "project_bucket" {
  name     = "${local.gcp-project}-bucket"
  location = local.gcp-region
}

resource "google_storage_bucket_object" "routes_fix_all_singlehomed" {
  name   = "net-fix-scripts-pnetlab/routes-fix-all-final.sh.singlehomed"
  bucket = google_storage_bucket.project_bucket.name
  source = "./assets-pnetlab/startup-scripts/routes-fix-all-final.sh.singlehomed"
}
```

### Step 10: Deploying and Configuring the First PNetLab VM

This is a key resource. It creates the main PNetLab virtual machine with a powerful machine type, the custom nested virtualization image, and **eight** network interfaces, each connected to a different VPC. A complex `startup-script` downloads and runs configuration scripts from the GCS bucket on first boot to correctly configure all network interfaces inside the OS.

```terraform
resource "google_compute_instance" "vdc_pnetlab_v5" {
  machine_type = "n2-highmem-8"
  name         = "vdc-pnetlab-v5"
  # ...
  boot_disk {
    initialize_params {
      image = google_compute_image.ubuntu_bionic_nested.self_link
    }
  }
  # ... 8 network_interface blocks ...
  metadata = {
    startup-script = <<EOF
      #!/bin/bash
      # ... downloads scripts from GCS and runs them ...
   EOF
  }
}
```

### Step 11 & 12: Automating Image Creation, Export, and Import

These sections automate the process of creating a distributable, pre-configured PNetLab image. They use `null_resource` with `local-exec` provisioners to run `gcloud` commands to stop the instance, create a new custom image from its disk, and export that image to a GCS bucket in `.vmdk` format. The reverse process, to import a `.vmdk` from a bucket and create a bootable GCE image, is also defined.

```terraform
resource "null_resource" "stop_instance" {
  # ... stops the vdc_pnetlab_v5 instance
}
resource "google_compute_image" "pnetlab_v5_custom_base" {
  name        = "vdc-pnetlab-v5-image-base"
  source_disk = google_compute_instance.vdc_pnetlab_v5.boot_disk[0].source
  depends_on  = [null_resource.stop_instance]
}
resource "null_resource" "vmdk_pnetlab_v5_custom" {
  provisioner "local-exec" {
    command = <<EOT
    gcloud compute images export \
    --destination-uri=gs://${google_storage_bucket.project_bucket.name}/.../pnetlab-v5-custom-base.vmdk \
    # ...
    EOT
  }
}
```

### Step 13: Deploying a Second PNetLab VM from the Custom Image

This creates a second PNetLab instance. The key difference is that instead of starting from a plain Ubuntu image, it uses the fully configured custom image created in the previous steps. This allows for much faster deployment of identical, pre-configured lab environments.

```terraform
resource "google_compute_instance" "vdc_pnetlab_v5_2" {
  name = "vdc-pnetlab-v5-2"
  # ...
  boot_disk {
    initialize_params {
      image = google_compute_image.pnetlab_v5_custom_base.self_link
    }
  }
  # ...
}
```

### Step 14: Deploying a Windows Jump Host

Finally, this section creates a Windows Server virtual machine to serve as a "jump host." This provides an easy-to-use graphical interface for accessing the lab environment. It uses a `sysprep-specialize-script-ps1` metadata key to run a PowerShell script on the first boot, which automates the entire setup of Chrome Remote Desktop for headless remote access.

```terraform
resource "google_compute_instance" "win_jh" {
  name         = local.win_jh_instance_name
  machine_type = "e2-medium"
  # ...
  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2022"
    }
  }
  # ...
  metadata = {
    crd-pin                       = var.crd_pin
    sysprep-specialize-script-ps1 = local.crd_sysprep_script_ps1_content
  }
}
```