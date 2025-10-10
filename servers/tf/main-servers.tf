terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.14.1"
    }
  }
}

provider "google" {
  project = local.gcp_project
  region  = local.gcp_region
  zone    = local.gcp_zone
}

# Data source to resolve image family to specific image
# When using a family name, this will always resolve to the latest image in that family
data "google_compute_image" "server_image" {
  family      = var.base_image
  project     = "ubuntu-os-pro-cloud"
  most_recent = true
}

# Generate individual script files for each server using templatefile() function
locals {
  # Get list of manifest files to upload to bucket
  manifest_files = fileset("${path.root}/manifests/", "*.yaml")

  network_setup_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/templates/01-network-setup.sh.tpl", {
      vm_name            = config.vm_name
      cluster_prefix     = config.cluster_prefix
      name_prefix        = config.name_prefix
      rack_prefix        = config.rack_prefix
      rack_id            = config.rack_id
      overlay_net        = config.overlay_net
      ip                 = config.ip
      stack              = config.stack
      machine_type       = config.machine_type
      underlay_net       = config.underlay_net
      mgmt_ip            = config.mgmt_ip
      vtep_ip            = config.vtep_ip
      overlay_ip         = config.overlay_ip
      overlay_gw         = config.overlay_gw
      vxlan_id           = config.vxlan_id
      pnet_vxlan         = config.pnet_vxlan
      gcp_project        = local.gcp_project
      gcp_zone           = local.gcp_zone
      pnetlab_mgmt_ip    = local.pnetlab_mgmt_ip
      pnetlab_vxlan_ip   = local.pnetlab_vxlan_ip
      pnetlab_last_octet = split(".", local.pnetlab_mgmt_ip)[3]

      # IPv6 configuration blocks
      ipv6_config = config.ipv6_overlay != null ? "# IPv6 configuration for dual stack\npnetipv6=\"${config.ipv6_overlay}\"\npnetipshortv6=\"$${pnetipv6%/*}\"\npnetgwv6=\"${config.ipv6_gw}\"" : "# IPv6 not configured for this server"

      ipv6_vxlan_config = config.ipv6_overlay != null ? "# IPv6 configuration for dual stack\nipv6vxlan=$(ip -6 -br addr show dev vxlan-overlay | awk '{print $3}')\nsudo ip -6 addr add $${pnetipv6} dev vxlan-overlay" : ""

      ipv6_route_config = config.ipv6_overlay != null ? "sudo ip -6 route add $${pnetgwv6} dev vxlan-overlay" : ""

      ipv6_default_route = config.ipv6_overlay != null ? "sudo ip -6 route add default via $${pnetgwv6}" : ""
    })
  }

  tools_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/templates/04-tools.sh.tpl", {
      vm_name     = config.vm_name
      name_prefix = config.name_prefix
      gcp_project = local.gcp_project
      gcp_zone    = local.gcp_zone

      # Workstation tools block
      workstation_tools = config.name_prefix == "ws" ? "# Workstation-specific tools and bmctl installation\nsudo -i\ncd /home\n\nPROJECT_ID=\"${local.gcp_project}\"\necho \"$${PROJECT_ID}\" > PROJECT_ID.txt\necho \"${local.gcp_zone}\" > ZONE.txt\n\n# Install kubectl\nsudo curl -LO \"https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl\"\nsudo chmod +x kubectl\nsudo mv kubectl /usr/local/sbin/\n\n# Create baremetal directory and install bmctl\nmkdir /home/baremetal && cd /home/baremetal\nBMCTL_VERSION='1.32.400-gke.68'\nsudo gsutil cp gs://anthos-baremetal-release/bmctl/$${BMCTL_VERSION}/linux-amd64/bmctl .\nsudo chmod a+x bmctl\nsudo mv bmctl /usr/local/sbin/\n\n# Install Docker\ncd ~\nsudo curl -fsSL https://get.docker.com -o get-docker.sh\nsudo sh get-docker.sh\n\n# Download GDC template manifests\nmkdir -p /home/baremetal/template_manifests\ngsutil cp -r gs://${data.google_storage_bucket.assets_bucket.name}/gdc-template-yamls/* /home/baremetal/template_manifests/" : config.name_prefix == "bgp" ? "# BGP server tools - create baremetal directory\nmkdir -p /home/baremetal" : "# No special tools for this server type"
    })
  }

  pnet_fdb_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/templates/02-pnet-server-fdb-add.sh.tpl", {
      vm_name         = config.vm_name
      rack_id         = config.rack_id
      overlay_net     = config.overlay_net
      underlay_net    = config.underlay_net
      vtep_ip         = config.vtep_ip
      pnet_vxlan      = config.pnet_vxlan
      pnetlab_mgmt_ip = local.pnetlab_mgmt_ip
      user_account    = data.terraform_remote_state.parent.outputs.user_account
    })
  }

  workstation_sa_config_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/templates/05-workstation-sa-config.sh.tpl", {
      # Service Account Key Management - pass existence flags and content
      gcr_key_exists       = local.gcr_key_exists
      connect_key_exists   = local.connect_key_exists
      register_key_exists  = local.register_key_exists
      cloud_ops_key_exists = local.cloud_ops_key_exists
      storage_key_exists   = local.storage_key_exists

      # Service account key content (base64 encoded for safe transport)
      gcr_key_content       = base64encode(local.gcr_key_content)
      connect_key_content   = base64encode(local.connect_key_content)
      register_key_content  = base64encode(local.register_key_content)
      cloud_ops_key_content = base64encode(local.cloud_ops_key_content)
      storage_key_content   = base64encode(local.storage_key_content)

      # Workload Identity message for .nokey files
      workload_identity_message = local.workload_identity_message
    })
  }

  bgp_sa_config_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/templates/05-bgp-sa-config.sh.tpl", {
      # Service Account Key Management - pass existence flags and content
      gcr_key_exists       = local.gcr_key_exists
      connect_key_exists   = local.connect_key_exists
      register_key_exists  = local.register_key_exists
      cloud_ops_key_exists = local.cloud_ops_key_exists
      storage_key_exists   = local.storage_key_exists

      # Service account key content (base64 encoded for safe transport)
      gcr_key_content       = base64encode(local.gcr_key_content)
      connect_key_content   = base64encode(local.connect_key_content)
      register_key_content  = base64encode(local.register_key_content)
      cloud_ops_key_content = base64encode(local.cloud_ops_key_content)
      storage_key_content   = base64encode(local.storage_key_content)

      # Workload Identity message for .nokey files
      workload_identity_message = local.workload_identity_message
    })
  }

  workstation_helpers_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/templates/06-workstation-helpers.sh.tpl", {
      vm_name     = config.vm_name
      rack_prefix = config.rack_prefix
      overlay_net = config.overlay_net
      overlay_ip  = config.overlay_ip
      gcp_project = local.gcp_project
    })
  }

  bgp_helpers_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/templates/07-bgp-helpers.sh.tpl", {
      vm_name     = config.vm_name
      rack_prefix = config.rack_prefix
      overlay_net = config.overlay_net
      overlay_ip  = config.overlay_ip
      gcp_project = local.gcp_project
    })
  }

  shutdown_cleanup_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/templates/99-shutdown-cleanup.sh.tpl", {
      vm_name         = config.vm_name
      rack_id         = config.rack_id
      overlay_net     = config.overlay_net
      underlay_net    = config.underlay_net
      vtep_ip         = config.vtep_ip
      overlay_ip      = config.overlay_ip
      pnet_vxlan      = config.pnet_vxlan
      pnetlab_mgmt_ip = local.pnetlab_mgmt_ip
    })
  }

  startup_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/startup-script-new.tpl", {
      vm_name          = config.vm_name
      cluster_prefix   = config.cluster_prefix
      name_prefix      = config.name_prefix
      rack_prefix      = config.rack_prefix
      rack_id          = config.rack_id
      overlay_net      = config.overlay_net
      ip               = config.ip
      stack            = config.stack
      machine_type     = config.machine_type
      underlay_net     = config.underlay_net
      mgmt_ip          = config.mgmt_ip
      vtep_ip          = config.vtep_ip
      overlay_ip       = config.overlay_ip
      overlay_gw       = config.overlay_gw
      vxlan_id         = config.vxlan_id
      pnet_vxlan       = config.pnet_vxlan
      ipv6_overlay     = config.ipv6_overlay != null ? config.ipv6_overlay : ""
      ipv6_gw          = config.ipv6_gw != null ? config.ipv6_gw : ""
      gcp_project      = local.gcp_project
      gcp_zone         = local.gcp_zone
      pnetlab_mgmt_ip  = local.pnetlab_mgmt_ip
      pnetlab_vxlan_ip = local.pnetlab_vxlan_ip
      bucket_name      = data.google_storage_bucket.assets_bucket.name

      # Pre-rendered script content - use local values instead of data.template_file
      network_setup_script_content         = local.network_setup_script[key]
      pnet_fdb_script_content              = local.pnet_fdb_script[key]
      tools_script_content                 = local.tools_script[key]
      workstation_sa_config_script_content = local.workstation_sa_config_script[key]
      bgp_sa_config_script_content         = local.bgp_sa_config_script[key]
      workstation_helpers_script_content   = local.workstation_helpers_script[key]
      bgp_helpers_script_content           = local.bgp_helpers_script[key]
      shutdown_cleanup_script_content      = local.shutdown_cleanup_script[key]

      # Service Account Key Management - pass existence flags and content
      gcr_key_exists       = local.gcr_key_exists
      connect_key_exists   = local.connect_key_exists
      register_key_exists  = local.register_key_exists
      cloud_ops_key_exists = local.cloud_ops_key_exists
      storage_key_exists   = local.storage_key_exists

      # Service account key content (base64 encoded for safe transport)
      gcr_key_content       = base64encode(local.gcr_key_content)
      connect_key_content   = base64encode(local.connect_key_content)
      register_key_content  = base64encode(local.register_key_content)
      cloud_ops_key_content = base64encode(local.cloud_ops_key_content)
      storage_key_content   = base64encode(local.storage_key_content)

      # Workload Identity message for .nokey files
      workload_identity_message = local.workload_identity_message
    })
  }

  shutdown_script = {
    for key, config in local.server_configs : key => templatefile("${path.module}/shutdown-script.tpl", {
      vm_name          = config.vm_name
      rack_prefix      = config.rack_prefix
      rack_id          = config.rack_id
      overlay_net      = config.overlay_net
      ip               = config.ip
      underlay_net     = config.underlay_net
      vtep_ip          = config.vtep_ip
      overlay_ip       = config.overlay_ip
      pnet_vxlan       = config.pnet_vxlan
      pnetlab_mgmt_ip  = local.pnetlab_mgmt_ip
      pnetlab_vxlan_ip = local.pnetlab_vxlan_ip
    })
  }
}

# Upload manifest files to bucket
resource "google_storage_bucket_object" "manifest_files" {
  for_each = local.manifest_files
  
  name   = "gdc-template-yamls/${each.value}"
  bucket = data.google_storage_bucket.assets_bucket.name
  source = "${path.root}/manifests/${each.value}"
  
  # Force re-upload if file content changes
  content_type = "application/x-yaml"
}

# Create local script files
resource "local_file" "network_setup_scripts" {
  for_each = local.server_configs

  content  = local.network_setup_script[each.key]
  filename = "${path.module}/generated-scripts/${each.value.vm_name}/01-network-setup.sh"

  file_permission = "0755"
}

resource "local_file" "tools_scripts" {
  for_each = local.server_configs

  content  = local.tools_script[each.key]
  filename = "${path.module}/generated-scripts/${each.value.vm_name}/04-tools.sh"

  file_permission = "0755"
}

resource "local_file" "pnet_fdb_scripts" {
  for_each = local.server_configs

  content  = local.pnet_fdb_script[each.key]
  filename = "${path.module}/generated-scripts/${each.value.vm_name}/02-pnet-server-fdb-add.sh"

  file_permission = "0755"
}

resource "local_file" "workstation_sa_config_scripts" {
  for_each = local.server_configs

  content  = local.workstation_sa_config_script[each.key]
  filename = "${path.module}/generated-scripts/${each.value.vm_name}/05-workstation-sa-config.sh"

  file_permission = "0755"
}

resource "local_file" "bgp_sa_config_scripts" {
  for_each = local.server_configs

  content  = local.bgp_sa_config_script[each.key]
  filename = "${path.module}/generated-scripts/${each.value.vm_name}/05-bgp-sa-config.sh"

  file_permission = "0755"
}

resource "local_file" "workstation_helpers_scripts" {
  for_each = local.server_configs

  content  = local.workstation_helpers_script[each.key]
  filename = "${path.module}/generated-scripts/${each.value.vm_name}/06-workstation-helpers.sh"

  file_permission = "0755"
}

resource "local_file" "bgp_helpers_scripts" {
  for_each = local.server_configs

  content  = local.bgp_helpers_script[each.key]
  filename = "${path.module}/generated-scripts/${each.value.vm_name}/07-bgp-helpers.sh"

  file_permission = "0755"
}

resource "local_file" "shutdown_cleanup_scripts" {
  for_each = local.server_configs

  content  = local.shutdown_cleanup_script[each.key]
  filename = "${path.module}/generated-scripts/${each.value.vm_name}/99-shutdown-cleanup.sh"

  file_permission = "0755"
}

# Cleanup generated script directories when servers are removed
resource "null_resource" "cleanup_generated_scripts" {
  for_each = local.server_configs

  # Store values in triggers for destroy-time access
  triggers = {
    vm_name = each.value.vm_name
  }

  # Clean up generated script directory when server is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${path.module}/generated-scripts/${self.triggers.vm_name}"
  }

  depends_on = [
    local_file.network_setup_scripts,
    local_file.tools_scripts,
    local_file.pnet_fdb_scripts,
    local_file.workstation_sa_config_scripts,
    local_file.bgp_sa_config_scripts,
    local_file.workstation_helpers_scripts,
    local_file.bgp_helpers_scripts,
    local_file.shutdown_cleanup_scripts
  ]
}


# Compute instances
resource "google_compute_instance" "servers" {
  for_each = local.server_configs

  name         = each.value.vm_name
  machine_type = each.value.machine_type
  zone         = local.gcp_zone

  # Enable IP forwarding for VXLAN and routing
  can_ip_forward = var.enable_ip_forwarding

  boot_disk {
    initialize_params {
      image = data.google_compute_image.server_image.self_link
      size  = var.disk_size
      type  = var.disk_type
    }
    device_name = each.value.vm_name
  }

  # Management network interface (VPC1)
  network_interface {
    network    = data.google_compute_network.vdc_vpc1.self_link
    subnetwork = data.google_compute_subnetwork.vpc1_subnets[each.value.vpc1_subnet_name].self_link
    network_ip = each.value.mgmt_ip
    # No external IP - using Cloud NAT
  }

  # VXLAN/Underlay network interface (VPC4)
  network_interface {
    network    = data.google_compute_network.vdc_vpc4.self_link
    subnetwork = data.google_compute_subnetwork.vpc4_subnets[each.value.vpc4_subnet_name].self_link
    network_ip = each.value.vtep_ip
    # No external IP - using Cloud NAT
  }

  # Service account configuration
  service_account {
    email  = "${local.gcp_project_number}-compute@developer.gserviceaccount.com"
    scopes = var.scopes
  }

  # Metadata configuration
  metadata = {
    enable-oslogin     = var.enable_oslogin
    serial-port-enable = "true"
    startup-script     = local.startup_script[each.key]
    #shutdown-script    = local.shutdown_script[each.key]
  }

  # Attach instance scheduling policies
  resource_policies = compact(concat(
    var.enable_auto_shutdown ? (length(data.google_compute_resource_policy.shutdown_schedule) > 0 ? [data.google_compute_resource_policy.shutdown_schedule[0].id] : []) : [],
    var.enable_auto_startup ? (length(data.google_compute_resource_policy.startup_schedule) > 0 ? [data.google_compute_resource_policy.startup_schedule[0].id] : []) : []
  ))

  # Scheduling configuration
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  # Shielded VM configuration
  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  # Tags for firewall rules
  tags = [each.value.cluster_prefix, each.value.rack_prefix]

  # Lifecycle management
  lifecycle {
    create_before_destroy = false
    # Ignore changes to boot disk image to prevent recreation when family image updates
    # Also ignore metadata changes to prevent instance recreation on script updates
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      metadata
    ]
  }

  # Dependencies
  depends_on = [
    data.google_compute_subnetwork.vpc1_subnets,
    data.google_compute_subnetwork.vpc4_subnets
  ]
}

# Local exec provisioner to track deployed VMs (similar to bash script)
resource "null_resource" "track_deployed_vms" {
  for_each = local.server_configs

  # Store values in triggers for destroy-time access
  triggers = {
    vm_name        = each.value.vm_name
    cluster_prefix = each.value.cluster_prefix
  }

  provisioner "local-exec" {
    command = "echo '${each.value.vm_name}' >> deployed-vms-${each.value.cluster_prefix}.txt"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/${self.triggers.vm_name}/d' deployed-vms-${self.triggers.cluster_prefix}.txt 2>/dev/null || true"
  }

  depends_on = [google_compute_instance.servers]
}

# Output information about deployed servers
output "deployed_servers" {
  description = "Information about deployed servers"
  value = {
    for server_name, config in local.server_configs : server_name => {
      vm_name      = config.vm_name
      mgmt_ip      = config.mgmt_ip
      vtep_ip      = config.vtep_ip
      overlay_ip   = config.overlay_ip
      rack_prefix  = config.rack_prefix
      overlay_net  = config.overlay_net
      machine_type = config.machine_type
      stack        = config.stack
    }
  }
}

output "deployment_summary" {
  description = "Summary of deployment"
  value = {
    total_servers = length(var.servers)
    servers_by_rack = {
      for rack in distinct([for config in local.server_configs : config.rack_prefix]) :
      rack => length([for config in local.server_configs : config if config.rack_prefix == rack])
    }
    servers_by_cluster = {
      for cluster in distinct([for config in local.server_configs : config.cluster_prefix]) :
      cluster => length([for config in local.server_configs : config if config.cluster_prefix == cluster])
    }
  }
}

# Output GCP commands for monitoring
output "monitoring_commands" {
  description = "Useful GCP commands for monitoring deployed instances"
  value = {
    list_instances = "gcloud compute instances list --filter='tags.items:(${join(" OR ", distinct([for config in local.server_configs : config.cluster_prefix]))})'"
    ssh_examples = {
      for server_name, config in local.server_configs : server_name =>
      "gcloud compute ssh ${config.vm_name} --zone=${local.gcp_zone} --tunnel-through-iap"
    }
  }
}
