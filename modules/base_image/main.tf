terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.0"
    }
  }
}

resource "libvirt_volume" "base_volume" {
  name   = "golden-arch.raw"
  pool   = var.pool_name
  source = var.base_image_path
  format = "raw"

}

output "base_volume_id" {
  value = libvirt_volume.base_volume.id
}