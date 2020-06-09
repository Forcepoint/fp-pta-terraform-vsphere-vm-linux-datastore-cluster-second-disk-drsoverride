# vsphere-vm-linux-datastore-cluster-second-disk-drsoverride Terraform Module

This contains an abstracted resource for creating a virtual machine with a Linux OS
on a specific datastore inside a datastore cluster. See https://www.terraform.io/docs/providers/vsphere/r/virtual_machine.html

In addition, this creates a second disk and attaches it to the virtual machine, and applies
a DRS VM Override on the VM. Doing this allows you to have the VM in the datastore cluster without
worry that DRS will automatically move the VM to another datastore in the cluster. If DRS did
move the VM, you terraform configuration would be invalid and it could not recover cleanly because
DRS will not move the attached disk with the VM and Terraform can't attach a disk on a different
datastore.

See the [variables.tf](variables.tf) file for descriptions of each variable. If default is not listed,
the variable is required. If a default is null, Terraform behaves as though you had completely 
omitted it.

Minimum Terraform Version: 0.12

For information about PTA and how to use it with this Terraform module please visit https://github.com/Forcepoint/fp-pta-overview/blob/master/README.md