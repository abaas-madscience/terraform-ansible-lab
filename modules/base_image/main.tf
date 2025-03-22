terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.0"
    }
  }
}


resource "null_resource" "download_base_image" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ./images
      if [ ! -f ${var.base_image_path} ]; then
        curl -L -o ${var.base_image_path} ${var.base_image_url}
      fi
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

resource "libvirt_volume" "base_volume" {
  name   = "base-ubuntu-jammy.qcow2"
  pool   = var.pool_name
  source = var.base_image_path
  format = "qcow2"

  depends_on = [
    null_resource.download_base_image
  ]
}

output "base_volume_id" {
  value = libvirt_volume.base_volume.id
}