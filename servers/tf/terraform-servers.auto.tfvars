# Server deployment configuration
# Define servers using the naming convention: cluster-prefix-node-type-rack-10-rack-id-overlay-net-ip-stack-machine-type

servers = [
  #   # workstation:
  "abm-ws-rs-10-99-101-10-ipv4-e2-standard-2",
  # 
  #   #admin cluster 01 (single node here):
  "abm10-adm01-r0-10-100-101-10-ipv4-n2-standard-4",
   
  #user cluster 1 (abm11): L2
  "abm11-cp01-r1-10-110-101-11-ipv4-n2-standard-4",
  "abm11-cp02-r1-10-110-101-12-ipv4-n2-standard-4",
  "abm11-cp03-r1-10-110-101-13-ipv4-n2-standard-4",
  "abm11-wk01-r1-10-110-101-15-ipv4-n2-standard-4",
  "abm11-wk02-r2-10-120-101-15-ipv4-n2-standard-4",
  "abm11-wk03-r3-10-130-101-15-ipv4-n2-standard-4",
   
  #   #bgp testing servers:
  #  "bgp-01-r1-10-110-103-99-e2-micro",
  #  "bgp-02-r2-10-120-103-99-e2-micro",
  #  "bgp-03-r3-10-130-103-99-e2-micro",

  #   #user cluster 2 (abm12): L3/BGP
  "abm12-cp01-r1-10-110-102-11-ipv4-n2-standard-4",
  "abm12-cp02-r2-10-120-102-11-ipv4-n2-standard-4",
  "abm12-cp03-r3-10-130-102-11-ipv4-n2-standard-4",
  "abm12-wk01-r1-10-110-102-15-ipv4-n2-standard-4",
  "abm12-wk02-r2-10-120-102-15-ipv4-n2-standard-4",
  "abm12-wk03-r3-10-130-102-15-ipv4-n2-standard-4",
  "abm12-wk04-r1-10-110-102-16-ipv4-n2-standard-4",
  "abm12-wk05-r2-10-120-102-16-ipv4-n2-standard-4",
  "abm12-wk06-r3-10-130-102-16-ipv4-n2-standard-4",
   
  #   #admin cluster node:
  #   "abm20-adm01-r0-10-100-105-10-ipv4-n2-standard-4",
  #   #user cluster 21 cp nodes:
  #   "abm21-cp01-r1-10-110-105-11-ipv4-n2-standard-4",  
  #   "abm21-cp02-r2-10-120-105-11-ipv4-n2-standard-4", 
  #   "abm21-cp03-r3-10-130-105-11-ipv4-n2-standard-4",  
  #   #user cluster 21 wk nodes: 
  #   "abm21-wk01-r1-10-110-105-15-ipv4-n2-standard-4",  
  #   "abm21-wk02-r2-10-120-105-15-ipv4-n2-standard-4",  
  #   "abm21-wk03-r3-10-130-105-15-ipv4-n2-standard-4",  
  #   #user cluster 21 lb nodes: 
  #   "abm21-lb01-r0-10-100-105-15-ipv4-n2-standard-4",  
  #   "abm21-lb02-r0-10-100-105-16-ipv4-n2-standard-4",  
  # 
  #   # Example dual-stack servers
  #   # "test-srv1-r2-10-120-106-15-ipv4ipv6-e2-medium",
  #   # "test-srv2-r3-10-130-107-16-ipv4ipv6-n2-standard-4",
]

# Optional: Override default settings
base_image           = "ubuntu-pro-2204-lts" #"ubuntu-pro-2004-lts"
disk_size            = 128
disk_type            = "pd-balanced"
enable_ip_forwarding = true
enable_oslogin       = true
scopes               = ["cloud-platform"]

# Auto-shutdown/startup configuration (should match main terraform configuration)
enable_auto_shutdown = true
enable_auto_startup  = false
