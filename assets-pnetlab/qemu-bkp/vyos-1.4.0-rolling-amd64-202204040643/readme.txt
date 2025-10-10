this qcow2 is the base disk image for vyos-1.4.0-rolling-amd64-202204040643 generated from its iso. It is to be placed in /opt/unetlab/addons/qemu/vyos-1.4.0-rolling-amd64-202204040643/
qcow2 is downloaded from the source storage bucket we are cloning during lab deployment. ()

gs://<bucket>>/custom-images/pnetlab/pnetlab-v5-lab-configured.tar.gz already has those qcow2 images. You would only need to download them from the bucket if wanting to build your own new pnetlab lab and needed the images for vyos and the configured domain controller.
