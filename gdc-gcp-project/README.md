# GDC Project Creation with Suffix Reuse

This directory contains Terraform configuration to create a new Google Distributed Cloud (GDC) project that reuses the suffix from the existing VDC project.

## Solution Overview

**Approach: Suffix injected from main.sh into terraform-gdc.tfvars**

The suffix is exported from `main.sh` and injected into `terraform-gdc.tfvars`, then used to create the GDC project under the same folder as the VDC project.

### How it Works

1. **Suffix Injection**: `main.sh` exports the `RANDOM_SUFFIX` to `terraform-gdc.tfvars`
2. **Project Creation**: Creates a new GDC project with the pattern `gdc-${suffix}`
3. **Shared Resources**: Uses the same folder and billing account as the VDC project
4. **Data Sources**: Retrieves billing account from the existing VDC project

## Files

- `main-gdc.tf`: Main Terraform configuration for GDC project creation
- `variables-gdc.tf`: Variable definitions for the GDC project
- `terraform-gdc.tfvars`: Variable values (suffix injected from main.sh)

## Variables Structure

The configuration uses a simplified variable structure:

```hcl
# From main project terraform.tfvars
user_account = "admin@meillier.altostrat.com"
path_module = "/Users/meillier/Documents/06-vscode/pnetlab-vdc-tf/vdc-lab-user"
orgid = "1061229561493"
gcp_region = "us-central1"

# Injected from main.sh
suffix = "08631"
```

## What Gets Created

The Terraform configuration creates:

1. **GDC Project**: `gdc-${suffix}` under the existing VDC folder `vdc-${suffix}`
2. **Required APIs**: Compute, Storage, IAM, etc.
3. **Storage Bucket**: `gdc-${suffix}-bucket` for project assets
4. **IAM Permissions**: User permissions on the new project

## Key Features

- **Shared Folder**: GDC project is created under the same folder as VDC project
- **Shared Billing**: Uses the same billing account as the VDC project (retrieved via data source)
- **Consistent Naming**: Both projects use the same suffix for easy identification
- **Automatic Discovery**: Billing account is automatically discovered from existing VDC project

## Usage

1. **Run main.sh** (which will inject the suffix):
   ```bash
   . ./main.sh
   ```

2. **Navigate to GDC directory**:
   ```bash
   cd gdc-gcp-project/tf
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the plan**:
   ```bash
   terraform plan -var-file=terraform-gdc.tfvars
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply -var-file=terraform-gdc.tfvars
   ```

## Example Output

Based on your current setup with suffix `08631`:

- **VDC project**: `vdc-08631` (existing)
- **GDC project**: `gdc-08631` (new)
- **Shared folder**: `vdc-08631` (folder ID: `149260220227`)
- **Shared billing**: `01B10A-601E21-33E959`
- **GDC storage bucket**: `gdc-08631-bucket`

## Integration with main.sh

To integrate this with your `main.sh` script, add this line after the `RANDOM_SUFFIX` is set:

```bash
# Export suffix to GDC terraform vars
echo "suffix = \"${RANDOM_SUFFIX}\"" >> gdc-gcp-project/tf/terraform-gdc.tfvars
```

## Benefits of This Approach

1. **Consistent with main.sh workflow**: Suffix is managed by the same script
2. **Shared Resources**: Uses same folder and billing account as VDC project
3. **Simple Variables**: Only essential variables needed
4. **Automatic Discovery**: Billing account discovered from existing project
5. **Clean Separation**: GDC config isolated but integrated with main workflow

## Validation

The configuration has been tested and validated:
- ✅ `terraform init` - Successfully initialized
- ✅ `terraform validate` - Configuration is valid
- ✅ `terraform plan` - Shows expected resources to be created

The plan shows it will create:
- 1 project (`gdc-08631`)
- 5 API services
- 3 IAM role bindings
- 1 storage bucket (`gdc-08631-bucket`)

## Data Sources Used

- `google_project.existing_vdc_project`: Gets VDC project info (folder_id, billing_account)
- `google_billing_account.account`: Gets billing account details from VDC project

This ensures the GDC project uses the same billing and organizational structure as the VDC project.
