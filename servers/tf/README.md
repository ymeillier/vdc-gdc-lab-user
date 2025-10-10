# Terraform Server Deployment

This Terraform configuration deploys GCE instances using the same naming convention and network configuration as the original bash scripts, but with the benefits of Terraform's declarative infrastructure management.

## Overview

This solution replicates the functionality of the bash script system (`00-template-flex-dhcpfix.sh` and server definition scripts like `01-servers-bgp.sh`) using Terraform.

## File Structure

```
servers/tf/
├── main.tf              # Main Terraform configuration with compute instances
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Server list and configuration values
├── locals.tf           # Server name parsing and configuration logic
├── data.tf             # Data sources for VPC networks and remote state
├── startup-script.tpl  # Startup script template for instances
├── shutdown-script.tpl # Shutdown script template for cleanup
└── README.md           # This file
```

## Server Naming Convention

Servers follow this naming pattern:
```
{cluster-prefix}-{node-type}-{rack}-10-{rack-id}-{overlay-net}-{ip}-{stack}-{machine-type}
```

### Examples:
- `bgp-ws-r0-10-100-107-99-ipv4-n2-standard-4`
- `abm1-cp1-r0-10-100-105-111-ipv4-e2-medium`
- `test-srv1-r2-10-120-106-115-ipv4ipv6-e2-medium` (dual-stack)

### Components:
- **cluster-prefix**: Cluster identifier (e.g., `bgp`, `abm1`, `test`)
- **node-type**: Node type (`ws`=workstation, `adm`=admin, `cp`=control-plane, `wk`=worker)
- **rack**: Rack location (`rs`, `r0`, `r1`, `r2`, `r3`, `r4`)
- **10**: Fixed value (always "10")
- **rack-id**: Calculated rack ID (rs=99, r0=100, r1=110, r2=120, r3=130, r4=140)
- **overlay-net**: Overlay network (100-109)
- **ip**: Last octet of IP address
- **stack**: IP stack (`ipv4` or `ipv4ipv6`)
- **machine-type**: GCE machine type (e.g., `e2-medium`, `n2-standard-4`)

## Prerequisites

1. **Parent Infrastructure**: The parent Terraform configuration must be deployed first to create VPCs and subnets
2. **Terraform State**: Parent `terraform.tfstate` file must exist in the parent directory
3. **PNet Server**: A PNet lab server must be running at `10.10.10.210` for VXLAN configuration

## Usage

### 1. Configure Servers

Edit `terraform.tfvars` to define the servers you want to deploy:

```hcl
servers = [
  "bgp-ws-r0-10-100-107-99-ipv4-n2-standard-4",
  "abm1-adm1-rs-10-99-105-110-ipv4-n2-standard-4",
  "abm1-cp1-r0-10-100-105-111-ipv4-e2-medium",
  # Add more servers as needed
]
```

### 2. Initialize Terraform

```bash
cd servers/tf
terraform init
```

### 3. Plan Deployment

```bash
terraform plan
```

This will show you:
- Which servers will be created
- Network configurations for each server
- Any validation errors

### 4. Deploy Servers

```bash
terraform apply
```

### 5. Monitor Deployment

Use the output commands to monitor your instances:

```bash
# List all deployed instances
gcloud compute instances list --filter='tags.items:(bgp OR abm1)'

# SSH to a specific instance
gcloud compute ssh bgp-ws-r0-10-100-107-99-ipv4 --zone=us-central1-a --tunnel-through-iap
```

### 6. Destroy Servers

```bash
terraform destroy
```

## Network Configuration

Each server gets:

### Management Interface (ens4)
- **Network**: VPC1 subnet based on rack and overlay
- **IP**: `10.10.{underlay_net}.{ip}`
- **Purpose**: Out-of-band management, GCP services access

### VXLAN Interface (ens5)
- **Network**: VPC4 subnet based on rack and overlay
- **IP**: `10.40.{underlay_net}.{ip}`
- **Purpose**: VXLAN tunnel endpoint

### Overlay Network (vxlan-overlay)
- **IP**: `10.{rack_id}.{overlay_net}.{ip}/24`
- **Gateway**: `10.{rack_id}.{overlay_net}.1`
- **Purpose**: Application networking through PNet fabric

## Features

### Automatic Network Configuration
- Dual-NIC setup with proper routing
- VXLAN tunnel to PNet server
- DNS configuration
- SSH access setup

### PNet Server Integration
- Automatic FDB entry creation
- Route configuration on PNet server
- Cleanup on instance termination

### Workstation Support
- Additional tools for `ws` (workstation) node types
- kubectl and bmctl installation
- Docker installation

### IPv6 Support
- Dual-stack configuration for `ipv4ipv6` servers
- IPv6 overlay networking

## Validation

The configuration includes validation for:
- Server name format (minimum 8 parts)
- Overlay network range (100-109)
- Rack prefix validity

## Troubleshooting

### Common Issues

1. **Missing Parent State**
   ```
   Error: Invalid data source
   ```
   - Ensure parent Terraform has been applied
   - Check `terraform.tfstate` exists in parent directory

2. **Subnet Not Found**
   ```
   Error: Subnet not found
   ```
   - Verify parent infrastructure includes required subnets
   - Check rack and overlay network values are valid

3. **Invalid Server Names**
   ```
   Error: validation failed
   ```
   - Ensure server names follow the naming convention
   - Check overlay networks are in range 100-109

### Debugging

1. **Check parsed server configurations**:
   ```bash
   terraform console
   > local.server_configs
   ```

2. **Validate network mappings**:
   ```bash
   terraform console
   > local.underlay_mapping
   ```

3. **Monitor instance startup**:
   ```bash
   gcloud compute instances tail-serial-port-output INSTANCE_NAME
   ```

## Migration from Bash Scripts

To migrate from the existing bash script system:

1. **Identify Current Servers**: List servers from your bash deployment files
2. **Convert Names**: Ensure names follow the exact convention
3. **Update terraform.tfvars**: Add server names to the `servers` list
4. **Deploy**: Run `terraform apply`
5. **Verify**: Check network connectivity and PNet integration

## Outputs

The configuration provides several useful outputs:

- **deployed_servers**: Detailed information about each deployed server
- **deployment_summary**: Statistics about the deployment
- **monitoring_commands**: GCP commands for monitoring instances
- **validation_errors**: Any configuration validation errors

## Advanced Configuration

### Custom Machine Types
Override the default machine type in server names or `terraform.tfvars`:
```hcl
default_machine_type = "n2-standard-2"
```

### Custom Images
Change the base image:
```hcl
base_image = "ubuntu-2004-focal-v20230605"
```

### Disk Configuration
Adjust disk size and type:
```hcl
disk_size = 256
disk_type = "pd-ssd"
