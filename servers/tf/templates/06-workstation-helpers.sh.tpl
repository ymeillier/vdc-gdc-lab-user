#!/bin/bash

# Create helper scripts for workstation operations
cd /home/baremetal

# BMctl commands reference
sudo cat > /home/baremetal/readme-bmctl-commands.txt << 'EENNDD'


#Install bmctl
https://cloud.google.com/kubernetes-engine/distributed-cloud/bare-metal/docs/downloads#download_bmctl



# bmctl Commands Reference
# https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/installing/creating-clusters/admin-cluster-creation#create_the_admin_cluster_with_the_cluster_config

export CLOUD_PROJECT_ID=$(gcloud config get-value project)
export ADMIN_CLUSTER_NAME=abm1-cluster-adm-${rack_prefix}-${overlay_net}



# Create cluster configuration
bmctl create config -c $ADMIN_CLUSTER_NAME --project-id=$CLOUD_PROJECT_ID

# Or with automatic API enablement and service account creation
bmctl create config -c $ADMIN_CLUSTER_NAME --enable-apis --create-service-accounts --project-id=$CLOUD_PROJECT_ID

# Transfer config to cloudshell for editing:
gcloud compute scp root@${vm_name}:/home/baremetal/bmctl-workspace/$ADMIN_CLUSTER_NAME/$ADMIN_CLUSTER_NAME.yaml ./

# Transfer back after editing:
gcloud compute scp ./$ADMIN_CLUSTER_NAME.yaml root@${vm_name}:~/baremetal/bmctl-workspace/$ADMIN_CLUSTER_NAME/

# Create cluster
bmctl create cluster -c $ADMIN_CLUSTER_NAME
EENNDD





# Cluster access reference
sudo cat > /home/baremetal/readme-cluster-access.txt << 'EENNDD'
# Cluster Access Reference
# https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/how-to/anthos-ui

export clusterid=abm1-adm-${overlay_net}
export KUBECONFIG=/home/baremetal/bmctl-workspace/$clusterid/$clusterid-kubeconfig
kubectl get nodes

GOOGLE_ACCOUNT_EMAIL=admin@example.com
PROJECT_ID=${gcp_project}
export CONTEXT="$(kubectl config current-context)"

gcloud container fleet memberships generate-gateway-rbac \
--membership=$clusterid \
--role=clusterrole/cluster-admin \
--users=$GOOGLE_ACCOUNT_EMAIL \
--project=$PROJECT_ID \
--kubeconfig=$KUBECONFIG \
--context=$CONTEXT \
--apply
EENNDD











# Netshoot reference
sudo cat > /home/baremetal/readme-netshoot.txt << 'EENNDD'
# Netshoot Deployment Reference
# kubectl run netshoot-lb01 -i --tty --image nicolaka/netshoot --overrides='{"apiVersion": "v1", "spec": {"nodeSelector": { "kubernetes.io/hostname": "abm11-lb01-r1-10-110-106-115-ipv4" }}}'
# kubectl expose pod netshoot-wk02 --type=LoadBalancer --target-port=1234 --port 1235
# iperf3 -s -p 1234 -B <IP>
EENNDD


# Create netshoot deployment script
sudo cat > /home/baremetal/deploy-netshoot.sh << 'EENNDD'
#!/bin/bash
# Deploy netshoot pod for network troubleshooting

if [ -z "$1" ]; then
    echo "Usage: $0 <node-name>"
    echo "Example: $0 abm1-wk01-r1-10-110-105-111-ipv4"
    exit 1
fi

NODE_NAME=$1
POD_NAME="netshoot-$(echo $NODE_NAME | cut -d'-' -f2-3)"

kubectl run $POD_NAME -i --tty --image nicolaka/netshoot \
--overrides='{"apiVersion": "v1", "spec": {"nodeSelector": { "kubernetes.io/hostname": "'$NODE_NAME'" }}}'
EENNDD

chmod +x /home/baremetal/deploy-netshoot.sh





## bgp advertiser 


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
