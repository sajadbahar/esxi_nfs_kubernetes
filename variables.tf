variable "vsphere_server" {}
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "guest_id" {}
variable "iso_file" {}

variable "k8s_masters" {
  type = map(object({
    host      = string
    num_cpus  = number
    memory    = number
    disk_size = number
  }))
  default = {
    master1 = {
      host      = "master1"
      num_cpus  = 4
      memory    = 4096
      disk_size = 8
    }
    master2 = {
      host      = "master2"
      num_cpus  = 4
      memory    = 4096
      disk_size = 8
    }
  }
}

variable "cluster_size" {
  default = 5
}

variable "cluster_node" {
  type = object({
    host      = string
    num_cpus  = number
    memory    = number
    disk_size = number
  })
  default = {
    host      = "worker"
    num_cpus  = 4
    memory    = 8192
    disk_size = 16
  }
}
