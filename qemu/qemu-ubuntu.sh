#!/bin/bash
# qemu-ubuntu.sh

# Prereqs:
#   brew install qemu cdrtools
#
# Create main disk image:
#   qemu-img create -f qcow2 hdd.qcow2 10G
#
# Create seed disk image:
#   $ cat metadata.yaml
#   instance-id: iid-local01
#   local-hostname: ubuntu
#
#   $ cat user-data.yaml
#   #cloud-config
#   password: ubuntu
#   chpasswd:
#     expire: False
#   ssh_pwauth: True
#   ssh_authorized_keys:
#     - 'ssh-ed25519 SOME-key...'
#
# On macos:
#   mkisofs -output seed.img -V cidata -J -r user-data.yaml metadata.yaml
#
# On Linux:
#   cloud-localds seed.img user-data.yaml metadata.yaml


IMG=mantic-minimal-cloudimg-amd64.img
if [[ ! -e $IMG ]]; then
    curl -LO https://cloud-images.ubuntu.com/daily/server/minimal/daily/mantic/current/$IMG
fi

qemu-system-x86_64 -nographic -m 4G -smp 2 -cpu Nehalem \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive if=virtio,format=qcow2,file=$IMG \
  -drive if=virtio,format=raw,file=seed.img
