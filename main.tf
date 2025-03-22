terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "ssh_key_path" {
  default = "~/.ssh/id_ed25519.pub"
}

locals {
  base_image_exists = fileexists("./images/jammy-server-cloudimg-amd64.img")
  pool_name = "k3vpool"
  workers = {
    "worker-01" = "192.168.178.101"
    "worker-02" = "192.168.178.102"
    "worker-03" = "192.168.178.103"
    "worker-04" = "192.168.178.104"
  }
}

data "template_file" "control_netconfig" {
  template = <<EOF
version: 2
ethernets:
  ens3:
    dhcp4: false
    addresses: [192.168.178.100/24]
    gateway4: 192.168.178.1
    nameservers:
      addresses: [192.168.178.2]
EOF
}

data "cloudinit_config" "control" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
hostname: control
users:
  - name: oscar
    ssh-authorized-keys:
      - ${file(var.ssh_key_path)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

package_update: true
package_upgrade: true

runcmd:
  - apt-get -y autoremove
  - apt-get -y clean 
  - reboot   
EOF
  }

  part {
    content_type = "text/network-config"
    content      = data.template_file.control_netconfig.rendered
  }
}

# Step 1, download the base image and store it in the images directory
resource "null_resource" "download_base_image" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ./images
      if [ ! -f ./images/jammy-server-cloudimg-amd64.img ]; then
        curl -L -o ./images/jammy-server-cloudimg-amd64.img \
        https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
      fi
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

# Step 1a, cleanup the old iso
resource "null_resource" "cleanup_old_iso" {
  provisioner "local-exec" {
    command = "virsh vol-delete --pool ${local.pool_name} control-cloudinit.iso || true"
  }

  triggers = {
    always_run = timestamp()
  }
}

resource "libvirt_volume" "base_volume" {
  name   = "base-ubuntu-jammy.qcow2"
  pool   = local.pool_name
  source = "./images/jammy-server-cloudimg-amd64.img"
  format = "qcow2"

  depends_on = [
    null_resource.download_base_image
  ]
}

# Create a 50GB volume for control node based on the base volume
resource "libvirt_volume" "vm_disk_control" {
  name           = "control.qcow2"
  pool           = local.pool_name
  base_volume_id = libvirt_volume.base_volume.id
  size           = 53687091200  # 50GB in bytes
}

resource "libvirt_cloudinit_disk" "control_ci" {
  name            = "control-cloudinit.iso"
  pool            = local.pool_name
  user_data       = data.cloudinit_config.control.rendered
  network_config  = data.template_file.control_netconfig.rendered

  depends_on = [
    null_resource.cleanup_old_iso,
    libvirt_volume.vm_disk_control
  ]
}

resource "libvirt_domain" "control" {
  name   = "control"
  memory = 8192 # in MB
  vcpu   = 8

  disk {
    volume_id = libvirt_volume.vm_disk_control.id
  }

  cloudinit = libvirt_cloudinit_disk.control_ci.id

  network_interface {
    network_name   = "k3vnet"
  }

  graphics {
    type = "vnc"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

data "template_file" "worker_netconfig" {
  for_each = local.workers

  template = <<EOF
version: 2
ethernets:
  ens3:
    dhcp4: false
    addresses: [${each.value}/24]
    gateway4: 192.168.178.1
    nameservers:
      addresses: [192.168.178.2]
EOF
}

data "cloudinit_config" "worker" {
  for_each = local.workers

  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
hostname: ${each.key}
users:
  - name: oscar
    ssh-authorized-keys:
      - ${file(var.ssh_key_path)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

package_update: true
package_upgrade: true

runcmd:
  - apt-get -y autoremove
  - apt-get -y clean
  - reboot
EOF
  }

  part {
    content_type = "text/network-config"
    content      = data.template_file.worker_netconfig[each.key].rendered
  }
}

resource "libvirt_cloudinit_disk" "worker_ci" {
  for_each        = local.workers
  name            = "${each.key}-cloudinit.iso"
  pool            = local.pool_name
  user_data       = data.cloudinit_config.worker[each.key].rendered
  network_config  = data.template_file.worker_netconfig[each.key].rendered
}

# Create 50GB volumes for worker nodes based on the base volume
resource "libvirt_volume" "worker_disk" {
  for_each = local.workers

  name           = "${each.key}.qcow2"
  pool           = local.pool_name
  base_volume_id = libvirt_volume.base_volume.id
  size           = 53687091200  # 50GB in bytes
}

resource "libvirt_domain" "worker" {
  for_each = local.workers

  name   = each.key
  memory = 4096
  vcpu   = 8

  disk {
    volume_id = libvirt_volume.worker_disk[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.worker_ci[each.key].id

  network_interface {
    network_name = "k3vnet"
  }

  graphics {
    type = "vnc"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}