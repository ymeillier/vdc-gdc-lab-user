#!/bin/bash

# Workstation Service Account Configuration
# This script creates service account key files or .nokey files based on availability

# Create the target directory
sudo mkdir -p /home/baremetal/sa-keys
cd /home/baremetal/sa-keys

# Anthos Baremetal GCR Service Account
%{ if gcr_key_exists ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-gcr.json << 'EEFFOLL'
${base64decode(gcr_key_content)}
EEFFOLL
%{ else ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-gcr.json.nokey << 'EEFFOLL'
${workload_identity_message}
EEFFOLL
%{ endif ~}

# Anthos Baremetal Connect Agent Service Account
%{ if connect_key_exists ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-connect-agent.json << 'EEFFOLL'
${base64decode(connect_key_content)}
EEFFOLL
%{ else ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-connect-agent.json.nokey << 'EEFFOLL'
${workload_identity_message}
EEFFOLL
%{ endif ~}

# Anthos Baremetal Connect Register Service Account
%{ if register_key_exists ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-connect-register.json << 'EEFFOLL'
${base64decode(register_key_content)}
EEFFOLL
%{ else ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-connect-register.json.nokey << 'EEFFOLL'
${workload_identity_message}
EEFFOLL
%{ endif ~}

# Anthos Baremetal Cloud Ops Service Account
%{ if cloud_ops_key_exists ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-cloud-ops.json << 'EEFFOLL'
${base64decode(cloud_ops_key_content)}
EEFFOLL
%{ else ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-cloud-ops.json.nokey << 'EEFFOLL'
${workload_identity_message}
EEFFOLL
%{ endif ~}

# Anthos Baremetal Cloud Storage Service Account
%{ if storage_key_exists ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-cloud-storage.json << 'EEFFOLL'
${base64decode(storage_key_content)}
EEFFOLL
%{ else ~}
sudo cat > /home/baremetal/sa-keys/anthos-baremetal-cloud-storage.json.nokey << 'EEFFOLL'
${workload_identity_message}
EEFFOLL
%{ endif ~}

# Create application default credentials if GCR key exists
%{ if gcr_key_exists ~}
sudo mkdir -p /root/.config/gcloud
sudo cp /home/baremetal/sa-keys/anthos-baremetal-gcr.json /root/.config/gcloud/application_default_credentials.json
%{ else ~}
sudo cat > /home/baremetal/sa-keys/application_default_credentials.json.nokey << 'EEFFOLL'
${workload_identity_message}
Use 'gcloud auth application-default login' for interactive authentication or configure Workload Identity.
EEFFOLL
%{ endif ~}
