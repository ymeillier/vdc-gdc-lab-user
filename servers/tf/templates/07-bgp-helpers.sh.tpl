#!/bin/bash

# Create BGP helper scripts and configuration
# First, create the baremetal directory if it doesn't exist
sudo mkdir -p /home/baremetal
cd /home/baremetal

# BGP Advertiser configuration template
sudo cat > /home/baremetal/conf-bgpadvertiser.conf << 'EENNDD'
localIP: ${overlay_ip}
localASN: 64600
peers:
#spine-a:
#- peerIP: 10.0.140.1
#  peerASN: 65003
#spine-b:
#- peerIP: 10.0.140.2
#  peerASN: 65003
#rs:
#- peerIP: 10.0.99.1
#  peerASN: 65004
#r0:
#- peerIP: 10.0.0.1
#  peerASN: 65010
#r1:
#- peerIP: 10.0.10.1
#  peerASN: 65011
#r2:
#- peerIP: 10.0.20.1
#  peerASN: 65012
#r3:
#- peerIP: 10.0.30.2
#  peerASN: 65013
EENNDD

# BGP Advertiser installation guide
sudo cat > /home/baremetal/readme-bgpadvertiser.readme << 'EENNDD'
Install bgpadvertiser following: https://cloud.google.com/kubernetes-engine/distributed-cloud/bare-metal/docs/how-to/lb-bundled-bgp#manual_bgp_verification

1. 
apt install docker.io

2. 
gcloud auth configure-docker

3. 
docker pull gcr.io/anthos-baremetal-release/ansible-runner:1.10.0-gke.13

4. 
docker cp $(docker create gcr.io/anthos-baremetal-release/ansible-runner:1.10.0-gke.13):/bgpadvertiser .


5. Example variables (Replace with your actual script logic)

Example: To Spine-A
NODE_IP="10.110.103.99"
CLUSTER_ASN="65003"
PEER_IP="10.0.140.1"
PEER_ASN="65003"
ADVERTISED_VIP=10.200.0.10

# Example: To R1-A
# NODE_IP="10.0.103.99"
# CLUSTER_ASN="65003"
# PEER_IP=""
# PEER_ASN=""


cat << EOF > /tmp/bgpadvertiser.conf
localIP: $${NODE_IP}
localASN: $${CLUSTER_ASN}
peers:
- peerIP: $${PEER_IP}
  peerASN: $${PEER_ASN}
EOF

6.
/tmp/bgpadvertiser --config /tmp/bgpadvertiser.conf --advertise-ip $ADVERTISED_VIP

7.
ip addr add ADVERTISED_VIP/32 dev vxlan-overlay


Cleanup

ip addr del ADVERTISED_VIP/32 dev vxlan-overlay
ps -ef | grep bgpadvertiser



# Metal-LB Example installation commands:
# wget https://github.com/metallb/metallb/releases/download/v0.13.7/metallb-native.yaml
# kubectl apply -f metallb-native.yaml
# kubectl apply -f conf-bgpadvertiser.conf
EENNDD

# Create BGP advertiser deployment script
sudo cat > /home/baremetal/deploy-bgpadvertiser.sh << 'EENNDD'
#!/bin/bash
# Deploy BGP advertiser for MetalLB

echo "Deploying BGP advertiser configuration..."
echo "Make sure to edit conf-bgpadvertiser.conf with your specific peer information"

if [ ! -f "conf-bgpadvertiser.conf" ]; then
    echo "Error: conf-bgpadvertiser.conf not found"
    exit 1
fi

kubectl apply -f conf-bgpadvertiser.conf
echo "BGP advertiser configuration applied"
EENNDD

#chmod +x /home/baremetal/deploy-bgpadvertiser.sh
