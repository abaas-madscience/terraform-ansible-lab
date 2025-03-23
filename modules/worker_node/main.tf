terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.0"
    }
  }
}

data "template_file" "worker_netconfig" {
  for_each = var.workers

  template = <<EOF
version: 2
ethernets:
  ens3:
    dhcp4: false
    addresses: [${each.value}/24]
    gateway4: ${var.network_config.gateway}
    nameservers:
      addresses: ${jsonencode(var.network_config.dns_servers)}
EOF
}

data "cloudinit_config" "worker" {
  for_each = var.workers

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
runcmd:
  - mkdir -p /etc/systemd/resolved.conf.d
  - bash -c "echo '[Resolve]' > /etc/systemd/resolved.conf.d/lab.conf"
  - bash -c "echo 'DNS=192.168.178.2' >> /etc/systemd/resolved.conf.d/lab.conf"
  - bash -c "echo 'Domains=lab.local' >> /etc/systemd/resolved.conf.d/lab.conf"
  - bash -c "echo 'FallbackDNS=1.1.1.1' >> /etc/systemd/resolved.conf.d/lab.conf"
  - systemctl restart systemd-resolved
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
  for_each        = var.workers
  name            = "${each.key}-cloudinit.iso"
  pool            = var.pool_name
  user_data       = data.cloudinit_config.worker[each.key].rendered
  network_config  = data.template_file.worker_netconfig[each.key].rendered
}

resource "libvirt_volume" "worker_disk" {
  for_each = var.workers

  name           = "${each.key}.qcow2"
  pool           = var.pool_name
  base_volume_id = var.base_volume_id
  size           = 53687091200  # 50GB in bytes
}

resource "libvirt_domain" "worker" {
  for_each = var.workers

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

output "worker_nodes_ips" {
  value = var.workers
}