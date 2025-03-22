variable "base_volume_id" {
  type = string
}

variable "pool_name" {
  type = string
}

variable "ssh_key_path" {
  type = string
}

variable "workers" {
  type = map(string)
}

variable "network_config" {
  type = object({
    gateway = string
    dns_servers = list(string)
  })
}