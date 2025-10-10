#!/bin/bash

ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo sed -i '/#from: ${vm_name}/d' /root/routes-fix-all-final.sh"

# --- Cleanup for BUM traffic forwarder ---
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo bridge fdb delete 00:00:00:00:00:00 dev ${pnet_vxlan} dst ${vtep_ip}"
ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo sed -i '/sudo bridge fdb append to 00:00:00:00:00:00 dev ${pnet_vxlan} dst ${vtep_ip}/d' /root/routes-fix-all-final.sh"



# --- Cleanup for unicast FDB entries ---
macaddress=$(ip -br link show vxlan-overlay | awk '{print $3}')
if [ -n "$macaddress" ]; then
    # Delete the running unicast FDB entries
    ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "bridge fdb delete $macaddress dev ${pnet_vxlan} dst ${vtep_ip} self"
    #ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "bridge fdb delete $macaddress dev ${pnet_vxlan} master pnet3"

    # Remove the corresponding lines from the pnet server's startup script
    ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sed -i \"/sudo bridge fdb add $macaddress dev ${pnet_vxlan} dst ${vtep_ip} self permanent/d\" /root/routes-fix-all-final.sh"
    #ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sed -i \"/sudo bridge fdb add $macaddress dev ${pnet_vxlan} master pnet3 permanent/d\" /root/routes-fix-all-final.sh"
fi

# --- Clean up routes and IPs if this is the last server on this overlay ---
#if [[ "${overlay_ip}" == "10.${rack_id}.${overlay_net}.10" ]]; then
#    # Delete the route
#    ssh -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo ip route delete 10.40.${underlay_net}.0/24 via 10.10.40.1 dev pnet3"
#    ssh -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo sed -i '/sudo ip route add 10.40.${underlay_net}.0\/24 via 10.10.40.1 dev pnet3/d' /root/routes-fix-all-final.sh"
#    
#    # Delete the overlay IP on the pnet bridge
#    pnetlab_last_octet=$(echo "${pnetlab_mgmt_ip}" | cut -d'.' -f4)
#    ssh -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo ip addr delete 10.${rack_id}.${overlay_net}.$pnetlab_last_octet/24 dev pnet3"
#    ssh -o StrictHostKeyChecking=no root@${pnetlab_mgmt_ip} "sudo sed -i '/sudo ip addr add 10.${rack_id}.${overlay_net}.$pnetlab_last_octet\/24 dev pnet3/d' /root/routes-fix-all-final.sh"
#fi
