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
    dhcp6: false
    addresses: [${var.network_config.ip_address}]
    gateway4: ${var.network_config.gateway}
    nameservers:
      addresses: ${jsonencode(var.network_config.dns_servers)}
    accept-ra: false
    link-local: []
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
  - mkdir -p /etc/systemd/resolved.conf.d
  - bash -c "echo '[Resolve]' > /etc/systemd/resolved.conf.d/lab.conf"
  - bash -c "echo 'DNS=192.168.178.2' >> /etc/systemd/resolved.conf.d/lab.conf"
  - bash -c "echo 'Domains=lab.local' >> /etc/systemd/resolved.conf.d/lab.conf"
  - bash -c "echo 'FallbackDNS=1.1.1.1' >> /etc/systemd/resolved.conf.d/lab.conf"
  - systemctl restart systemd-resolved
  - bash -c "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/99-disable-ipv6.conf"
  - bash -c "echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.d/99-disable-ipv6.conf"
  - bash -c "echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/99-disable-ipv6.conf"
  - sysctl --system
  - apt-get -y autoremove
  - apt-get -y clean
  - apt install qemu-guest-agent -y
  - systemctl enable --now qemu-guest-agent
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
  vcpu   = 16

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