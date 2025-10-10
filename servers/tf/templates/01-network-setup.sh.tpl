#!/bin/bash

# Change root color prompt
sudo tee -a /root/.bashrc << EOF
PS1='$${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF

# Get MAC addresses
macens4=$(sudo cat /sys/class/net/ens4/address)
macens5=$(sudo cat /sys/class/net/ens5/address)

sudo ip link set ens4 address $${macens4}
sudo ip link set ens5 address $${macens5}

echo $${macens4} > macens4.txt
echo $${macens5} > macens5.txt
echo ${mgmt_ip} > ipens4.txt
echo ${vtep_ip} > ipens5.txt

# Prevent DHCP from breaking routing table
cat > /etc/dhcp/dhclient-exit-hooks.d/postdhcp.sh << 'DNE'
#!/bin/bash
case "$${reason}" in (BOUND|RENEW|REBIND)
    sudo netplan apply
    ;;
esac
DNE
chmod +x /etc/dhcp/dhclient-exit-hooks.d/postdhcp.sh

# Configure interfaces via netplan
cat > /etc/netplan/00-netplanpostboot.yaml << 'END'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens4:
      dhcp4: false
      dhcp6: false 
      addresses:
      - ${mgmt_ip}/32
      routes:
      - to: 10.10.${underlay_net}.1
      - to: 35.235.0.0/16
        via: 10.10.${underlay_net}.1
      - to: 216.239.0.0/16
        via: 10.10.${underlay_net}.1
      - to: 169.254.169.254
        via: 10.10.${underlay_net}.1
      - to: ${pnetlab_mgmt_ip}/32
        via: 10.10.${underlay_net}.1
    ens5:
      dhcp4: false
      dhcp6: false 
      addresses:
      - ${vtep_ip}/32
      routes:
      - to: 10.40.${underlay_net}.1
      - to: 10.40.${underlay_net}.0/24
        via: 10.40.${underlay_net}.1      
      - to: 10.10.40.${pnetlab_last_octet}/32
        via: 10.40.${underlay_net}.1
END

# Disable cloud-init network config
cat >> /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg << 'ENDD'
network: {config: disabled}
ENDD
sudo mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.old

# Kill DHCP client to prevent route overwrites
pkill dhclient

sudo netplan apply

# Set interface MTUs
sudo ip link set dev ens4 mtu 8896
sudo ip link set dev ens5 mtu 8896
sudo ip link set dev lo mtu 8846

# Network variables
gcpip="${vtep_ip}"
underlaynetoctet=${underlay_net}

# Extract last octet from PNetLab server's management IP for VXLAN configuration
pnetlab_last_octet=$(echo "${pnetlab_mgmt_ip}" | cut -d'.' -f4)

# Generate list of potential GCP IPs for FDB entries
declare -a gcpIPs=()
for ((i=2; i<=254; i++)); do
    gcpIPs+=("10.40.${underlay_net}.$${i}")
done

# Overlay network configuration
pnetip="${overlay_ip}/24"
pnetipshort="${overlay_ip}"
pnetgw="${overlay_gw}"

${ipv6_config}

vxlanid=${vxlan_id}
pnetlabvxlan="${pnet_vxlan}"

# Change root password and SSH settings
sudo chpasswd <<<"root:pnet"
if [[ "$(uname -s)" == "Darwin" ]]; then
    sudo sed -i '' 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
    sudo sed -i '' 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sudo sed -i '' 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
else
    sudo sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
fi

# Configure routing for GCP services
sudo ip route add 35.235.0.0/16 via 10.10.${underlay_net}.1 dev ens4
sudo ip route add 216.239.0.0/16 via 10.10.${underlay_net}.1 dev ens4
sudo ip route add 169.254.169.254 via 10.10.${underlay_net}.1 dev ens4

# Routes for management network
sudo ip route add 10.10."$${underlaynetoctet}".1 dev ens4
sudo ip route add 10.10.10.0/24 via 10.10."$${underlaynetoctet}".1 dev ens4

# Route to pnet server via secondary interface
sudo ip route add 10.10.40.0/24 via 10.40."$${underlaynetoctet}".1 dev ens5

# Set up VXLAN over ens5
sudo ip link add vxlan-overlay type vxlan id "$${vxlanid}" dstport 0 dev ens5 remote 10.10.40.$${pnetlab_last_octet}
sudo ip link set dev vxlan-overlay mtu 8846
sudo ip link set dev vxlan-overlay up

# Add server IP for vDC networking
sudo ip addr add "$${pnetip}" dev vxlan-overlay

${ipv6_vxlan_config}

# Set default route through pnet fabric
sudo ip route add "$${pnetgw}" dev vxlan-overlay
${ipv6_route_config}

sudo ip route delete default dev ens4
sudo ip route add default via "$${pnetgw}" src "$${pnetipshort}" dev vxlan-overlay
${ipv6_default_route}

# DNS configuration
if [[ "$(uname -s)" == "Darwin" ]]; then
    sudo sed -i '' 's/#DNS=/DNS=10.99.100.10/g' /etc/systemd/resolved.conf
    sudo sed -i '' 's/#FallbackDNS=/FallbackDNS=127.0.0.53/g' /etc/systemd/resolved.conf
else
    sudo sed -i 's/#DNS=/DNS=10.99.100.10/g' /etc/systemd/resolved.conf
    sudo sed -i 's/#FallbackDNS=/FallbackDNS=127.0.0.53/g' /etc/systemd/resolved.conf
fi
sudo service systemd-resolved restart

# Manual DNS configuration
sudo touch /etc/resolv.conf.manually-configured
sudo cp /etc/resolv.conf /etc/resolv.conf.manually-configured
sudo mv /etc/resolv.conf /etc/resolv.conf.old
if [[ "$(uname -s)" == "Darwin" ]]; then
    sed -i '' '/nameserver 127.0.0.53/a\nameserver 10.99.100.10' /etc/resolv.conf.manually-configured
    sudo sed -i '' 's/search us-central1-a.c.${gcp_project}.internal c.${gcp_project}.internal google.internal/& acme.local/' /etc/resolv.conf.manually-configured
else
    sed -i '/nameserver 127.0.0.53/a\nameserver 10.99.100.10' /etc/resolv.conf.manually-configured
    sudo sed -i 's/search us-central1-a.c.${gcp_project}.internal c.${gcp_project}.internal google.internal/& acme.local/' /etc/resolv.conf.manually-configured
fi
sudo ln -s /etc/resolv.conf.manually-configured /etc/resolv.conf

# Add FDB entries for other neighbors on overlay network
sudo echo start > /home/fdb-appended.txt
for ipvar in $${gcpIPs[@]}; do
     if [ "$${ipvar}" != "$${gcpip}" ]; then
            sudo echo $${ipvar} >> /home/fdb-appended.txt
            sudo bridge fdb append to 00:00:00:00:00:00 dst $${ipvar} dev vxlan-overlay
     fi
done

# Configure inotify kernel parameters for increased file watching limits
sudo sysctl -w fs.inotify.max_user_instances=8192
sudo sysctl -w fs.inotify.max_user_watches=1000000

# Make inotify settings persistent across reboots
sudo tee -a /etc/sysctl.conf << 'INOTIFY_EOF'
# Increased inotify limits for container workloads
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 655360
INOTIFY_EOF


ulimit -n 65535  #Should be at least 65535

# Disable UFW firewall service
sudo systemctl stop ufw
sudo systemctl disable ufw
