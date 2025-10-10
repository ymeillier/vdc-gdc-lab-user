#!/bin/bash

# Startup script for server: ${vm_name}
# Generated from Terraform template - uses pre-generated script files





### Explanation
#
#
#       startup-script.tpl is the template used by terraform  during the deployment of the compute instances (resource "google_compute_instance" "servers") via metadata specifications in
# 
#          metadata = {
#             enable-oslogin     = var.enable_oslogin
#             serial-port-enable = "true"
#             startup-script     = data.template_file.startup_script[each.key].rendered
#             shutdown-script    = data.template_file.shutdown_script[each.key].rendered
#          }
# 
#         the startup script used during the creation of a server instance is parameterized via startup-script.tpl 
#         in that script, it does the following. 
# 
#         1 - create /home/01-network-setup.sh via the cat > /home/01-network-setup.sh << 'EOOF' ... EOOF block.
#         the GCE instance startup script then proceeds with running that sub script with  sudo /home/01-network-setup.sh
# 
#         2- creates 02-pnet-server-fdb-add.sh via cat > /home/02-pnet-server-fdb-add.sh << 'EFOL' ... EFOL 
#         and  then executes that script  via sudo /home/02-pnet-server-fdb-add.sh
# 
#         3- creates /home/04-tools.sh via the cat > /home/04-tools.sh << 'EFOL' ... EFOL block.
#         This will be executed later after the code has a chance to see if the instances is workstation to add additional scripts to it before its execution (section 4 below).
# 
#         4- if prefix of the instance name is ws (e.g. name_prefix == "ws") it then does a couple additional additions.
# 
#         4a- adds additional tools to  to /home/04-tools.sh via the block cat >> /home/04-tools.sh << 'SEEFOLL' ... SEEFOLL
# 
#         4b- still within the conditional check on instance being a workstation (e.g. name_prefix == "ws"), it creates /home/05-workstation-sa-config.sh via cat > /home/05-workstation-sa-config.sh << 'WSCONFIG'
# 
#         the scripts proceeds with running: /home/05-workstation-sa-config.sh via sudo /home/05-workstation-sa-config.sh
# 
#         4c-creates /home/06-workstation-helpers.sh via cat > /home/06-workstation-helpers.sh << 'WSHELPERS' which itself, once run, woud create the following  assets
# 
#         4c.a- creates a reference commands text file readme-cluster-access.txt via sudo cat > /home/baremetal/readme-cluster-access.txt << 'EENNDD'
# 
#         4c.b - creates/home/baremetal/readme-netshoot.txt via sudo cat > /home/baremetal/readme-netshoot.txt << 'EENNDD'
# 
#         4c.c- creates /home/baremetal/conf-bgpadvertiser.conf via  sudo cat > /home/baremetal/conf-bgpadvertiser.conf << 'EENNDD'
# 
#         4c.d - creates /home/baremetal/readme-bgpadvertiser.readme via sudo cat > /home/baremetal/readme-bgpadvertiser.readme << 'EENNDD'
# 
#         4c.e- create/home/baremetal/deploy-netshoot.sh via sudo cat > /home/baremetal/deploy-netshoot.sh << 'EENNDD'
# 
#         4c.f - creates home/baremetal/deploy-bgpadvertiser.sh via sudo cat > /home/baremetal/deploy-bgpadvertiser.sh << 'EENNDD'
# 
#         This ends  the content of /home/06-workstation-helpers.sh
#         it is then executed by the startup script in order to create those assets using sudo /home/06-workstation-helpers.sh.
# 
#         this ends the conditional check to add additional scripts if the instance is a workstation. 
# 
#         then tools.sh is executed via sudo /home/04-tools.sh
# 
#         the startup-script also creates a shutdown  bash script /home/99-shutdown-cleanup.sh via cat > /home/99-shutdown-cleanup.sh << 'EOFF'.
# 
#   Script execution conditional logic:
#             conditional logic within startup-script.tpl, where the above 4 scripts are only executed if it is the first time the instance boots up. What we could do is create marker files in /home as part of each script being executed (/home/01-network-setup.sh, /home/02-pnet-server-fdb-add.sh, /home/04-tools.sh,/home/05-workstation-sa-config.sh ) like /home/01-network-setup.sh.ran, /home/02-pnet-server-fdb-add.sh.ran, /home/04-tools.sh.ran,/home/05-workstation-sa-config.sh.ran
#             each of those marker files would have content "marker file created the first time the instance was created to indicate that the script was ran once already and thus no longer needs to be run during future instance restarts".
#             the script would then only be executed if the marker files cannot be found. 




# Set variables from template
export CLUSTER_PREFIX="${cluster_prefix}"
export NAME_PREFIX="${name_prefix}"
export RACK_PREFIX="${rack_prefix}"
export RACK_ID="${rack_id}"
export OVERLAY_NET="${overlay_net}"
export IP="${ip}"
export STACK="${stack}"
export MACHINE_TYPE="${machine_type}"
export UNDERLAY_NET="${underlay_net}"
export MGMT_IP="${mgmt_ip}"
export VTEP_IP="${vtep_ip}"
export OVERLAY_IP="${overlay_ip}"
export OVERLAY_GW="${overlay_gw}"
export VXLAN_ID="${vxlan_id}"
export PNET_VXLAN="${pnet_vxlan}"
export PROJECT_ID="${gcp_project}"
%{ if ipv6_overlay != "" ~}
export IPV6_OVERLAY="${ipv6_overlay}"
export IPV6_GW="${ipv6_gw}"
%{ endif ~}

# Disable login banner
touch ~/.hushlogin












# BEGIN ####### /home/01-network-setup.sh #########################
# Create the pre-generated network setup script
cat > /home/01-network-setup.sh << 'NETWORK_SCRIPT_EOF'
${network_setup_script_content}
NETWORK_SCRIPT_EOF

# Set permissions and execute network setup script
sudo chmod +x /home/01-network-setup.sh
sudo /home/01-network-setup.sh
# /END ####### /home/01-network-setup.sh #########################


















# /BEGIN ####### no /home/02-pnet-server-fdb-add.sh.ran #########################
# Create and execute pnet server FDB add script (only on first boot)
if [ ! -f /home/02-pnet-server-fdb-add.sh.ran ]; then
    cat > /home/02-pnet-server-fdb-add.sh << 'PNET_FDB_SCRIPT_EOF'
${pnet_fdb_script_content}
PNET_FDB_SCRIPT_EOF

    # Execute pnet server FDB add script
    sudo chmod +x /home/02-pnet-server-fdb-add.sh
    sudo /home/02-pnet-server-fdb-add.sh
    
    # Create marker file
    echo "marker file created the first time the instance was created to indicate that it no longer needs to be run during future restarts" > /home/02-pnet-server-fdb-add.sh.ran
fi
# /END #######  no /home/02-pnet-server-fdb-add.sh.ran #########################


















# /BEGIN ####### no /home/04-tools.sh.ran #########################
# Create and execute tools installation script (only on first boot)
if [ ! -f /home/04-tools.sh.ran ]; then

    cat > /home/04-tools.sh << 'TOOLS_SCRIPT_EOF'
${tools_script_content}
TOOLS_SCRIPT_EOF

    # Execute tools installation script
    sudo chmod +x /home/04-tools.sh
    sudo /home/04-tools.sh

    # /BEGIN ####### name_prefix == "ws"  #########################
    %{ if name_prefix == "ws" ~}

    # Create and execute workstation-specific service account configuration script (only on first boot)
    if [ ! -f /home/05-workstation-sa-config.sh.ran ]; then
        cat > /home/05-workstation-sa-config.sh << 'WSCONFIG_SCRIPT_EOF'
${workstation_sa_config_script_content}
WSCONFIG_SCRIPT_EOF
        #
        # Execute workstation service account configuration
        sudo chmod +x /home/05-workstation-sa-config.sh
        sudo /home/05-workstation-sa-config.sh
        #            
        # Create marker file
        echo "marker file created the first time the instance was created to indicate that the script was ran once already and thus no longer needs to be run during future instance restarts" > /home/05-workstation-sa-config.sh.ran
    fi

    # Create workstation helper scripts
    cat > /home/06-workstation-helpers.sh << 'WSHELPERS_SCRIPT_EOF'
${workstation_helpers_script_content}
WSHELPERS_SCRIPT_EOF
    #
    # Execute workstation helper scripts creation
    sudo chmod +x /home/06-workstation-helpers.sh
    sudo /home/06-workstation-helpers.sh
    #
    %{ endif ~}
    # /END #######  name_prefix == "ws" #########################

    # /BEGIN ####### { cluster_prefix == "bgp" ~} #########################
    %{ if cluster_prefix == "bgp" ~}
    # Create BGP helper scripts
    cat > /home/07-bgp-helpers.sh << 'BGPHELPERS_SCRIPT_EOF'
${bgp_helpers_script_content}
BGPHELPERS_SCRIPT_EOF
    #
    # Execute BGP helper scripts creation
    sudo chmod +x /home/07-bgp-helpers.sh
    sudo /home/07-bgp-helpers.sh
    #

    # Create and execute bgp-specific service account configuration script (only on first boot)
    if [ ! -f /home/05-bgp-sa-config.sh.ran ]; then
        cat > /home/05-bgp-sa-config.sh << 'BGPCONFIG_SCRIPT_EOF'
${bgp_sa_config_script_content}
BGPCONFIG_SCRIPT_EOF
        #
        # Execute bgp service account configuration
        sudo chmod +x /home/05-bgp-sa-config.sh
        sudo /home/05-bgp-sa-config.sh
        #            
        # Create marker file
        echo "marker file created the first time the instance was created to indicate that the script was ran once already and thus no longer needs to be run during future instance restarts" > /home/05-bgp-sa-config.sh.ran
    fi
    %{ endif ~}
    # /END ####### { cluster_prefix == "bgp" ~} #########################

    # Create marker file
    echo "marker file created the first time the instance was created to indicate that the script was ran once already and thus no longer needs to be run during future instance restarts" > /home/04-tools.sh.ran

fi
# /END ####### no /home/04-tools.sh.ran #########################


















# Create shutdown cleanup script
cat > /home/99-shutdown-cleanup.sh << 'SHUTDOWN_SCRIPT_EOF'
${shutdown_cleanup_script_content}
SHUTDOWN_SCRIPT_EOF

# Make shutdown cleanup script executable
sudo chmod +x /home/99-shutdown-cleanup.sh


















# Log deployment completion
echo "✅ Deployed GCE instance ${vm_name}"
echo "  - Instance IP on mgmt vpc subnet: ${mgmt_ip}"
echo "  - Instance IP on vxlan vpc subnet: ${vtep_ip}"
echo "  - Instance IP on overlay: ${overlay_ip}/24"
