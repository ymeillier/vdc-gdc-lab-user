these custom images are used as base GCE image to deploy two versions of our pnetlab server. 
The base image has pnetlab v5 installed on ubuntu 18.04. No network script was run to customize the routing table since that has to be run with the exact ip used by the server.

The second image is a fully configured pnetlab lab. The spine leaf lab with only the leg-A of our routers configured (except R3, which has R3B configured and not R3-A. R4 has both TORs configured. also Spine A and B are both configured).
IT also has the windows server vm configured. its qcow2 has been saved under assets pnetlab