# Service Account Key Parameterization

This document explains how the server deployment system now dynamically handles service account keys from the GDC project, supporting both traditional key-based authentication and Workload Identity-based deployments.

## Overview

The system has been updated to:
1. **Dynamically read service account keys** from the GDC project's `SA-keys/` folder
2. **Support Workload Identity fallback** when keys are not available
3. **Restore missing workstation functionality** including netshoot and BGP advertiser tools
4. **Provide conditional authentication setup** based on key availability

## How It Works

### Key Detection Logic

The system checks for service account key files in `../gdc-gcp-project/tf/SA-keys/` and:
- **If keys exist**: Creates normal `.json` files with actual key content
- **If keys don't exist**: Creates `.nokey` files with Workload Identity message

### Service Account Files Created

For workstation VMs (`name_prefix == "ws"`), the following files are created in `/home/baremetal/`:

#### When Keys Are Available:
- `anthos-baremetal-gcr.json`
- `anthos-baremetal-connect-agent.json`
- `anthos-baremetal-connect-register.json`
- `anthos-baremetal-cloud-ops.json`
- `anthos-baremetal-cloud-storage.json`
- `application_default_credentials.json` (copy of GCR key)

#### When Keys Are Not Available (Workload Identity):
- `anthos-baremetal-gcr.json.nokey`
- `anthos-baremetal-connect-agent.json.nokey`
- `anthos-baremetal-connect-register.json.nokey`
- `anthos-baremetal-cloud-ops.json.nokey`
- `anthos-baremetal-cloud-storage.json.nokey`
- `application_default_credentials.json.nokey`

All `.nokey` files contain the message:
```
No keys were created for the service account to enforce Workload Identity based cluster deployments.
```

## Workstation Features Restored

### BMctl Integration
- Automatic bmctl installation (version 1.15.4)
- kubectl installation
- Docker installation
- Project ID and zone configuration

### Helper Scripts and Documentation
- `readme-bmctl-commands.txt` - BMctl usage examples
- `readme-cluster-access.txt` - Cluster access configuration
- `readme-netshoot.txt` - Network troubleshooting pod deployment
- `readme-bgpadvertiser.readme` - BGP advertiser installation guide

### Deployment Scripts
- `deploy-netshoot.sh` - Automated netshoot pod deployment
- `deploy-bgpadvertiser.sh` - BGP advertiser configuration deployment
- `conf-bgpadvertiser.conf` - BGP configuration template

## Testing the Implementation

### Test Scenario 1: With Service Account Keys

1. **Deploy GDC project with keys**:
   ```bash
   cd gdc-gcp-project/tf
   terraform apply
   ```

2. **Verify keys are created**:
   ```bash
   ls -la SA-keys/
   # Should show: anthos-baremetal-*.json files
   ```

3. **Deploy workstation server**:
   ```bash
   cd ../../servers/tf
   terraform apply
   ```

4. **SSH to workstation and verify**:
   ```bash
   gcloud compute ssh <workstation-vm-name> --zone=<zone> --tunnel-through-iap
   sudo su -
   cd /home/baremetal
   ls -la *.json
   # Should show actual JSON key files
   ```

### Test Scenario 2: Without Service Account Keys (Workload Identity)

1. **Remove or rename SA-keys folder**:
   ```bash
   cd gdc-gcp-project/tf
   mv SA-keys SA-keys.backup  # or rm -rf SA-keys
   ```

2. **Deploy workstation server**:
   ```bash
   cd ../../servers/tf
   terraform apply
   ```

3. **SSH to workstation and verify**:
   ```bash
   gcloud compute ssh <workstation-vm-name> --zone=<zone> --tunnel-through-iap
   sudo su -
   cd /home/baremetal
   ls -la *.nokey
   # Should show .nokey files with Workload Identity message
   cat anthos-baremetal-gcr.json.nokey
   ```

## File Structure

```
servers/tf/
├── data.tf                    # Service account key detection logic
├── main-servers.tf           # Template variable passing
├── startup-script.tpl        # Conditional key file creation
└── README-service-account-keys.md  # This documentation

gdc-gcp-project/tf/
└── SA-keys/                  # Service account keys folder
    ├── anthos-baremetal-gcr.json
    ├── connect-agent.json
    ├── connect-register.json
    ├── anthos-baremetal-cloud-ops.json
    └── storage-bucket-accessor.json
```

## Migration from Hardcoded Keys

The old `00-template-flex-dhcpfix.sh` script contained hardcoded service account keys. This new implementation:

1. **Removes security risk** of hardcoded keys in code
2. **Provides flexibility** to use either authentication method
3. **Maintains compatibility** with existing workflows
4. **Adds missing functionality** that was present in the original script

## Troubleshooting

### Keys Not Found
If you see `.nokey` files but expect actual keys:
1. Check that GDC project has been deployed: `cd gdc-gcp-project/tf && terraform apply`
2. Verify SA-keys folder exists: `ls -la gdc-gcp-project/tf/SA-keys/`
3. Check file permissions on key files

### Authentication Issues
- **With Keys**: Verify JSON files are valid and contain proper service account information
- **With Workload Identity**: Use `gcloud auth application-default login` for interactive authentication

### Path Issues
The system expects the GDC project to be at `../gdc-gcp-project/tf/SA-keys/` relative to the servers terraform directory. Adjust the `sa_keys_path` in `data.tf` if your structure is different.

## Benefits

1. **Security**: No hardcoded keys in source code
2. **Flexibility**: Supports both authentication methods
3. **Maintainability**: Single source of truth for service account keys
4. **Future-proof**: Aligns with Google's Workload Identity recommendations
5. **Complete**: Restores all missing workstation functionality
