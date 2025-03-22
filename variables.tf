variable "k3vpool_path" {
  default = "/var/lib/libvirt/images/k3vpool"
}
variable "pool_name" {
  default = "k3vpool"
}

variable "ssh_key_path" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "workers" {
  default = {
    "worker-01" = "192.168.178.101"
    "worker-02" = "192.168.178.102"
    "worker-03" = "192.168.178.103"
    "worker-04" = "192.168.178.104"
  }
}