#!/bin/bash
touch ./04-tools.running
# Install dependencies for Kubernetes/container workloads
sudo apt-get update
sudo apt-get install socat -y
sudo apt-get install conntrack -y
sudo apt-get install ebtables -y
sudo apt-get install ipset -y
sudo apt-get install net-tools -y
sudo apt-get install traceroute -y
sudo apt-get install bridge-utils -y
sudo apt-get install ipvsadm -y 
sudo apt install jq -y 

# Download and install vimcat
sudo wget https://github.com/ofavre/vimcat/releases/download/v1.0.0/vimcat_1.0.0-1_all.deb
apt-get install -y ./vimcat_1.0.0-1_all.deb

${workstation_tools}

sudo rm ./04-tools.running
