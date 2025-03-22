terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.0"
    }
  }
}


data "template_file" "control_netconfig" {
  template = <<EOF
version: 2
ethernets:
  ens3:
    dhcp4: false
    addresses: [${var.network_config.ip_address}]
    gateway4: ${var.network_config.gateway}
    nameservers:
      addresses: ${jsonencode(var.network_config.dns_servers)}
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

resource "libvirt_volume" "vm_disk_control" {
  name           = "control.qcow2"
  pool           = var.pool_name
  base_volume_id = var.base_volume_id
  size           = 53687091200  # 50GB in bytes
}

resource "libvirt_cloudinit_disk" "control_ci" {
  name            = "control-cloudinit.iso"
  pool            = var.pool_name
  user_data       = data.cloudinit_config.control.rendered
  network_config  = data.template_file.control_netconfig.rendered
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

output "control_node_ip" {
  value = var.network_config.ip_address
}