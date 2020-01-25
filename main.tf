data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = var.vsphere_datastore_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "vlan_main" {
  name          = var.vlan_main
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_clone_from
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "null_resource" "disk_prefix" {
  triggers = {
    prefix = var.name
  }

  lifecycle {
    ignore_changes = [
      "triggers",
    ]
  }
}

resource "vsphere_virtual_disk" "extra_disk" {
  size       = var.second_disk_size
  vmdk_path  = "PTA_${null_resource.disk_prefix.triggers.prefix}_extra.vmdk"
  datacenter = data.vsphere_datacenter.dc.name
  datastore  = data.vsphere_datastore.datastore.name
  type       = var.second_disk_type
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.name
  folder           = var.folder
  resource_pool_id = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus          = var.num_cpus
  memory            = var.memory
  guest_id          = data.vsphere_virtual_machine.template.guest_id
  nested_hv_enabled = var.nested_hv_enabled
  scsi_type         = data.vsphere_virtual_machine.template.scsi_type

  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout
  shutdown_wait_timeout      = var.shutdown_wait_timeout

  network_interface {
    network_id   = data.vsphere_network.vlan_main.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  disk {
    label            = "disk1"
    path             = vsphere_virtual_disk.extra_disk.vmdk_path
    unit_number      = 1
    attach           = true
    datastore_id     = data.vsphere_datastore.datastore.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    timeout       = var.clone_timeout

    customize {
      linux_options {
        host_name = var.name
        domain    = var.domain
        time_zone = var.time_zone
      }

      network_interface {
        ipv4_address    = var.ipv4_address
        ipv4_netmask    = var.ipv4_netmask
        ipv6_address    = var.ipv6_address
        ipv6_netmask    = var.ipv6_netmask
      }

      ipv4_gateway    = var.ipv4_gateway
      ipv6_gateway    = var.ipv6_gateway
      dns_suffix_list = var.dns_suffix_list
      dns_server_list = var.dns_server_list

      timeout         = var.customize_timeout
    }
  }
}

resource "vsphere_storage_drs_vm_override" "drs_vm_override" {
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
  virtual_machine_id   = vsphere_virtual_machine.vm.id
  sdrs_enabled         = false
}