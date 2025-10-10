#!/bin/bash


# why fdb add required on the pnet server. 
    # # When connected works (vai the pnetlab fabric), the pnetserver will have 2 fdb entries for our remote server vxlan-overlay mac address:
    # 
    # abm-ws-rs-10-99-101-10-ipv4:~$ ip -br link show
    # lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
    # ens4             UP             42:01:0a:0a:5b:0a <BROADCAST,MULTICAST,UP,LOWER_UP> 
    # ens5             UP             42:01:0a:28:5b:0a <BROADCAST,MULTICAST,UP,LOWER_UP> 
    # vxlan-overlay    UNKNOWN        8e:0b:9a:d3:b6:95 <BROADCAST,MULTICAST,UP,LOWER_UP> 
    # docker0          DOWN           be:2a:60:9b:dc:1d <NO-CARRIER,BROADCAST,MULTICAST,UP> 
    # br-f114c1e3a383  DOWN           42:5a:86:a1:c7:43 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
    # 
    # 
    # vdc-pnetlab-v5-2:~$ bridge fdb show | grep 8e:0b:9a:d3:b6:95
    # 8e:0b:9a:d3:b6:95 dev vxlan-rs master pnet3 
    # 8e:0b:9a:d3:b6:95 dev vxlan-rs dst 10.40.91.10 self
    # that server is on the service rack so the fdb entry is for the vxlan-rs interface of the pnet server.
    # 
    # 
    # when connectivity breaks, those entries are gone.
    # 
    # bridge fdb will never need one for 00:00:00:00:00:00
    # $ bridge fdb show | grep 00:00:00:00:00:00
    # admin_meillier_altostrat_com@vdc-pnetlab-v5-2:~$
    # 
    # so that is why we have this script.



# SSH key setup for pnet server communication
# Download SSH keys directly from the bucket where the pnetlab server stored them

echo "Downloading SSH keys from bucket..."

# Create .ssh directory for root if it doesn't exist
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Download SSH keys from bucket
PROJECT_ID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")
BUCKET_NAME="$${PROJECT_ID}-bucket-clone"

echo "Downloading private key..."
gsutil cp "gs://$${BUCKET_NAME}/assets-pnetlab/pnetserver-sshkey/id_rsa" /root/.ssh/id_rsa
if [ $? -eq 0 ]; then
    chmod 600 /root/.ssh/id_rsa
    echo "✅ Private key downloaded successfully"
else
    echo "❌ Failed to download private key"
    touch /root/.ssh/failed-to-download-private-key.txt
fi

echo "Downloading public key..."
gsutil cp "gs://$${BUCKET_NAME}/assets-pnetlab/pnetserver-sshkey/id_rsa.pub" /root/.ssh/id_rsa.pub
if [ $? -eq 0 ]; then
    chmod 644 /root/.ssh/id_rsa.pub
    echo "✅ Public key downloaded successfully"
    
    # Add public key to authorized_keys
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
else
    echo "❌ Failed to download public key"
    touch /root/.ssh/failed-to-download-public-key.txt
fi

# Also set up keys for the user account if it exists
user_account="${user_account}"
if [ -n "$user_account" ]; then
    linux_user=$(echo "$user_account" | sed 's/[@._-]/_/g')
    
    # Check if the user exists
    if id -u "$linux_user" >/dev/null 2>&1; then
        echo "Setting up SSH keys for user: $linux_user"
        
        # Ensure home directory exists
        if [ ! -d "/home/$linux_user" ]; then
            mkhomedir_helper "$linux_user"
        fi
        
        # Create .ssh directory
        mkdir -p "/home/$linux_user/.ssh"
        chmod 700 "/home/$linux_user/.ssh"
        
        # Copy keys from root
        if [ -f "/root/.ssh/id_rsa" ]; then
            cp /root/.ssh/id_rsa "/home/$linux_user/.ssh/id_rsa"
            chmod 600 "/home/$linux_user/.ssh/id_rsa"
        fi
        
        if [ -f "/root/.ssh/id_rsa.pub" ]; then
            cp /root/.ssh/id_rsa.pub "/home/$linux_user/.ssh/id_rsa.pub"
            chmod 644 "/home/$linux_user/.ssh/id_rsa.pub"
            
            # Add to authorized_keys
            cat "/home/$linux_user/.ssh/id_rsa.pub" >> "/home/$linux_user/.ssh/authorized_keys"
            chmod 600 "/home/$linux_user/.ssh/authorized_keys"
        fi
        
        # Set ownership
        chown -R "$linux_user:$linux_user" "/home/$linux_user/.ssh"
    fi
fi


# --- FDB & Route Configuration on PNET Server ---

ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "echo '#from: ${vm_name}' | sudo tee -a /root/routes-fix-all-final.sh"

# 1. Add BUM traffic forwarder
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo bridge fdb append to 00:00:00:00:00:00 dev ${pnet_vxlan} dst ${vtep_ip}"
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "echo 'sudo bridge fdb append to 00:00:00:00:00:00 dev ${pnet_vxlan} dst ${vtep_ip}' | sudo tee -a /root/routes-fix-all-final.sh"

# 2. Add Unicast FDB entries
macaddress=$(ip -br link show vxlan-overlay | awk '{print $3}')
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "bridge fdb add $macaddress dev ${pnet_vxlan} dst ${vtep_ip} self permanent"
#ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "bridge fdb add $macaddress dev ${pnet_vxlan} master pnet3 permanent"
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "echo \"sudo bridge fdb add $macaddress dev ${pnet_vxlan} dst ${vtep_ip} self permanent\" | tee -a /root/routes-fix-all-final.sh"
#ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "echo \"sudo bridge fdb add $macaddress dev ${pnet_vxlan} master pnet3 permanent\" | tee -a /root/routes-fix-all-final.sh"

# # 3. Add route to new VM network: we alread have a 10.40.0.0/16 route
# sudo ssh -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo ip route add 10.40.${underlay_net}.0/24 via 10.10.40.1 dev pnet3"
# sudo ssh -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "echo 'sudo ip route add 10.40.${underlay_net}.0/24 via 10.10.40.1 dev pnet3' | sudo tee -a /root/routes-fix-all-final.sh"

# # 4. Add overlay IP to pnet server bridge (not necesary. but this will allow the pnet server to ping the other server on its vxlan-overlay. not really needed. what is need is routing to the TEP)
# pnetlab_last_octet=$(echo "${pnetlab_mgmt_ip}" | cut -d'.' -f4)
# sudo ssh -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo ip addr add 10.${rack_id}.${overlay_net}.$pnetlab_last_octet/24 dev pnet3"
# sudo ssh -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "echo 'sudo ip addr add 10.${rack_id}.${overlay_net}.$pnetlab_last_octet/24 dev pnet3' | sudo tee -a /root/routes-fix-all-final.sh"
