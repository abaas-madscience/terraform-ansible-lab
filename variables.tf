variable "k3vpool_path" {
  default = "/var/lib/libvirt/images/k3vpool"
}
variable "pool_name" {
  default = "k3vpool"
}

variable "ssh_key_path" {
  default = "~/.ssh/id_ed25519.pub"  
}

# Make sure you only have one SSH key in authorized hosts
variable "ssh_authorized_path" {
  default = "~/.ssh/authorized_keys"  
}

variable "workers" {
  default = {
    "worker-01" = "192.168.178.101"
    "worker-02" = "192.168.178.102"
    "worker-03" = "192.168.178.103"
    "worker-04" = "192.168.178.104"
  }
}

variable "raw_image_path" {
  default = "./images/golden-arch.raw"
}

variable "raw_image_size" {
  default = "50G"
}