## Configure the vSphere Provider
provider "vsphere" {
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_user
  password             = var.vsphere_password
  allow_unverified_ssl = true
}

## Build VM
data "vsphere_datacenter" "dc" {
  name = "ha-datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "iso_datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {}

data "vsphere_network" "PortGroup" {
  name          = "PrivateNetwork-PortGroup"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = "localhost.localdomain"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "nfs_server" {

  name             = "NFS-Server"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus                   = 2
  memory                     = 2048
  wait_for_guest_net_timeout = 0
  guest_id                   = var.guest_id

  nested_hv_enabled = true
  annotation        = "NFS Server"

  network_interface {
    network_id = data.vsphere_network.PortGroup.id
  }

  disk {
    label            = "nfs_server.vmdk"
    size             = 200
    eagerly_scrub    = false
    thin_provisioned = true
  }

  cdrom {
    datastore_id = data.vsphere_datastore.iso_datastore.id
    path         = var.iso_file
  }
}


resource "vsphere_virtual_machine" "master_nodes" {

  for_each = var.k8s_masters

  name             = "k8s_${each.value.host}"
  resource_pool_id = data.vsphere_host.host.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus   = each.value.num_cpus
  memory     = each.value.memory
  guest_id   = var.guest_id
  annotation = "Deployed with Terraform"

  network_interface {
    network_id = data.vsphere_network.PortGroup.id
  }

  disk {
    label            = "k8s_${each.value.host}.vmdk"
    size             = each.value.disk_size
    eagerly_scrub    = false
    thin_provisioned = true
  }

  cdrom {
    datastore_id = data.vsphere_datastore.iso_datastore.id
    path         = var.iso_file
  }
}

resource "vsphere_virtual_machine" "cluster_nodes" {

  count = var.cluster_size

  name             = "${var.cluster_node.host}_${count.index}"
  resource_pool_id = data.vsphere_host.host.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus   = var.cluster_node.num_cpus
  memory     = var.cluster_node.memory
  guest_id   = var.guest_id
  annotation = "Deployed with Terraform"

  network_interface {
    network_id = data.vsphere_network.PortGroup.id
  }

  disk {
    label            = "${var.cluster_node.host}_${count.index}.vmdk"
    size             = var.cluster_node.disk_size
    eagerly_scrub    = false
    thin_provisioned = true
  }

  cdrom {
    datastore_id = data.vsphere_datastore.iso_datastore.id
    path         = var.iso_file
  }
}
