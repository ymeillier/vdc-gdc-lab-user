locals {
  # Extract variables from parent state - fail if missing rather than using outdated fallbacks
  gcp_project        = data.terraform_remote_state.parent.outputs.gcp_project
  gcp_region         = data.terraform_remote_state.parent.outputs.gcp_region
  gcp_zone           = data.terraform_remote_state.parent.outputs.gcp_zone
  gcp_project_number = data.terraform_remote_state.parent.outputs.gcp_project_number
  user_account       = data.terraform_remote_state.parent.outputs.user_account

  # Parse server names into components
  parsed_servers = {
    for server in var.servers : server => {
      parts = split("-", server)

      # Extract components based on naming convention
      cluster_prefix = split("-", server)[0]
      name_prefix    = split("-", server)[1]
      rack_prefix    = split("-", server)[2]
      fixed_10       = split("-", server)[3] # Should always be "10"
      rack_vlan      = split("-", server)[4] # This becomes part of rack_id calculation
      overlay_net    = split("-", server)[5]
      ip             = split("-", server)[6]
      stack          = split("-", server)[7]

      # Machine type can be 2 or 3 parts (e.g., "e2-medium" or "n2-standard-4")
      machine_type = length(split("-", server)) >= 11 ? "${split("-", server)[8]}-${split("-", server)[9]}-${split("-", server)[10]}" : length(split("-", server)) >= 10 ? "${split("-", server)[8]}-${split("-", server)[9]}" : var.default_machine_type
    }
  }

  # Calculate rack IDs based on rack prefix (replicating bash logic)
  rack_id_mapping = {
    "rs" = "99"
    "r0" = "100"
    "r1" = "110"
    "r2" = "120"
    "r3" = "130"
    "r4" = "140"
  }

  # Calculate underlay network mapping for each rack and overlay combination
  underlay_mapping = {
    "rs" = {
      "100" = "90", "101" = "91", "102" = "92", "103" = "93", "104" = "94",
      "105" = "95", "106" = "96", "107" = "97", "108" = "98", "109" = "99"
    }
    "r0" = {
      "100" = "100", "101" = "101", "102" = "102", "103" = "103", "104" = "104",
      "105" = "105", "106" = "106", "107" = "107", "108" = "108", "109" = "109"
    }
    "r1" = {
      "100" = "110", "101" = "111", "102" = "112", "103" = "113", "104" = "114",
      "105" = "115", "106" = "116", "107" = "117", "108" = "118", "109" = "119"
    }
    "r2" = {
      "100" = "120", "101" = "121", "102" = "122", "103" = "123", "104" = "124",
      "105" = "125", "106" = "126", "107" = "127", "108" = "128", "109" = "129"
    }
    "r3" = {
      "100" = "130", "101" = "131", "102" = "132", "103" = "133", "104" = "134",
      "105" = "135", "106" = "136", "107" = "137", "108" = "138", "109" = "139"
    }
    "r4" = {
      "100" = "140", "101" = "141", "102" = "142", "103" = "143", "104" = "144",
      "105" = "145", "106" = "146", "107" = "147", "108" = "148", "109" = "149"
    }
  }

  # Enhanced server configuration with calculated values
  server_configs = {
    for server_name, parsed in local.parsed_servers : server_name => {
      # Basic parsed values
      cluster_prefix = parsed.cluster_prefix
      name_prefix    = parsed.name_prefix
      rack_prefix    = parsed.rack_prefix
      overlay_net    = parsed.overlay_net
      ip             = parsed.ip
      stack          = parsed.stack
      machine_type   = parsed.machine_type

      # Calculated values
      rack_id      = local.rack_id_mapping[parsed.rack_prefix]
      underlay_net = local.underlay_mapping[parsed.rack_prefix][parsed.overlay_net]

      # Network configuration
      mgmt_ip    = "10.10.${local.underlay_mapping[parsed.rack_prefix][parsed.overlay_net]}.${parsed.ip}"
      vtep_ip    = "10.40.${local.underlay_mapping[parsed.rack_prefix][parsed.overlay_net]}.${parsed.ip}"
      overlay_ip = "10.${local.rack_id_mapping[parsed.rack_prefix]}.${parsed.overlay_net}.${parsed.ip}"

      # Subnet names
      vpc1_subnet_name = "vdc-vpc1-net-${parsed.rack_prefix}-10-${local.underlay_mapping[parsed.rack_prefix][parsed.overlay_net]}"
      vpc4_subnet_name = "vdc-vpc4-net-${parsed.rack_prefix}-40-${local.underlay_mapping[parsed.rack_prefix][parsed.overlay_net]}"

      # VM name for GCE instance
      vm_name = "${parsed.cluster_prefix}-${parsed.name_prefix}-${parsed.rack_prefix}-10-${local.rack_id_mapping[parsed.rack_prefix]}-${parsed.overlay_net}-${parsed.ip}-${parsed.stack}"

      # IPv6 configuration (if dual stack)
      ipv6_overlay = parsed.stack == "ipv4ipv6" ? "fd::${local.rack_id_mapping[parsed.rack_prefix]}:${parsed.overlay_net}:0:0:0:${parsed.ip}/64" : null
      ipv6_gw      = parsed.stack == "ipv4ipv6" ? "fd::${local.rack_id_mapping[parsed.rack_prefix]}:${parsed.overlay_net}:0:0:0:1111" : null

      # VXLAN configuration
      vxlan_id   = local.rack_id_mapping[parsed.rack_prefix]
      pnet_vxlan = "vxlan-${parsed.rack_prefix}"

      # Gateway IPs
      overlay_gw = "10.${local.rack_id_mapping[parsed.rack_prefix]}.${parsed.overlay_net}.1"
    }
  }

  # Collect all required subnets for data source lookups
  required_vpc1_subnets = toset([
    for config in local.server_configs : config.vpc1_subnet_name
  ])

  required_vpc4_subnets = toset([
    for config in local.server_configs : config.vpc4_subnet_name
  ])

  # Validate overlay networks are in allowed range (100-109)
  valid_overlay_nets = toset(["100", "101", "102", "103", "104", "105", "106", "107", "108", "109"])

  # Check for invalid overlay networks
  invalid_overlays = [
    for server_name, config in local.server_configs : server_name
    if !contains(local.valid_overlay_nets, local.parsed_servers[server_name].overlay_net)
  ]

  # Extract pnetlab server IP information from the data source
  pnetlab_mgmt_ip  = data.google_compute_instance.pnetlab_server.network_interface[0].network_ip
  pnetlab_vxlan_ip = data.google_compute_instance.pnetlab_server.network_interface[1].network_ip

  # Extract the last octet from the management IP (e.g., "210" from "10.10.10.210")
  pnetlab_mgmt_octet  = split(".", local.pnetlab_mgmt_ip)[3]
  pnetlab_vxlan_octet = split(".", local.pnetlab_vxlan_ip)[3]
}

# Output validation errors if any
output "validation_errors" {
  value = length(local.invalid_overlays) > 0 ? {
    invalid_overlay_networks = "The following servers have invalid overlay networks (must be 100-109): ${join(", ", local.invalid_overlays)}"
  } : null
}
