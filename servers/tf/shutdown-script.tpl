#!/bin/bash

# The entire thing is commented out for now cause we want to make sure not shut down script is run when power cycling vms.
# 
# # Shutdown script for server: ${vm_name}
# # This script cleans up network configurations on the pnet server
# 
# # Execute the cleanup script that was created during startup
# if [ -f /home/99-shutdown-cleanup.sh ]; then
#     /home/99-shutdown-cleanup.sh
# else
#     # Fallback cleanup if script doesn't exist
#     echo "Performing fallback cleanup for ${vm_name}"
#     
#     # Clean up FDB entry on pnet server
#     ssh -o StrictHostKeyChecking=no root@10.10.10.210 "sudo bridge fdb delete 00:00:00:00:00:00 dev ${pnet_vxlan} dst ${vtep_ip}" 2>/dev/null || true
#     
#     # Clean up config file entry
#     ssh -o StrictHostKeyChecking=no root@10.10.10.210 "sed -i '/sudo bridge fdb append to 00:00:00:00:00:00 dev ${pnet_vxlan} dst ${vtep_ip}/d' /home/routes-fix-all-final.sh" 2>/dev/null || true
#     
#     # Clean up routes and IPs if this is the .10 IP (last server on this overlay)
#     if [[ "${overlay_ip}" == "10.${rack_id}.${overlay_net}.10" ]]; then
#         ssh -o StrictHostKeyChecking=no root@10.10.10.210 "sudo ip route delete 10.40.${underlay_net}.0/24 via 10.10.40.1 dev pnet3" 2>/dev/null || true
#         ssh -o StrictHostKeyChecking=no root@10.10.10.210 "sed -i '/sudo ip route add 10.40.${underlay_net}.0\/24 via 10.10.40.1 dev pnet3/d' /home/routes-fix-all-final.sh" 2>/dev/null || true
#         ssh -o StrictHostKeyChecking=no root@10.10.10.210 "sudo ip addr delete 10.${rack_id}.${overlay_net}.210/24 dev pnet3" 2>/dev/null || true
#         ssh -o StrictHostKeyChecking=no root@10.10.10.210 "sed -i '/sudo ip addr add 10.${rack_id}.${overlay_net}.210\/24 dev pnet3/d' /home/routes-fix-all-final.sh" 2>/dev/null || true
#     fi
# fi
# 
# echo "Cleanup completed for ${vm_name}"
