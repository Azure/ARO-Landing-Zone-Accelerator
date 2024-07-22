@export()
@description('The visibility of a resource. Possible values are: Private, Public.')
type visibilityType = 'Private' | 'Public'

@export()
@description('Set if the encryption at host is enabled or disabled. Possible values are: Disabled, Enabled.')
type encryptionAtHostType = 'Disabled' | 'Enabled'

@export()
@description('The size of the master VM.')
type masterNodesVmSizeType = 'Standard_D8s_v5' | 'Standard_D16s_v5' | 'Standard_D32s_v5' | 'Standard_D8as_v5' | 'Standard_D16as_v5' | 'Standard_D32as_v5' | 'Standard_E8s_v5' | 'Standard_E16s_v5' | 'Standard_E20s_v5' | 'Standard_E32s_v5' | 'Standard_E48s_v5' | 'Standard_E64s_v5' | 'Standard_E96s_v5'| 'Standard_E104is_v5' | 'Standard_E8as_v5' | 'Standard_E16as_v5' | 'Standard_E20as_v5' | 'Standard_E32as_v5' | 'Standard_E48as_v5' | 'Standard_E64as_v5' | 'Standard_E96as_v5' | 'Standard_E104ids_v5' | 'Standard_F72s_v2' | 'Standard_M128ms'

@export()
@description('The worker profile.')
type workerProfileType = {
  @description('The name of the worker profile.')
  name: string

  @description('The number of worker VMs.')
  count: int

  @description('The size of the VM.')
  vmSize: string

  @description('The size of the disk in GB.')
  @minValue(128)
  diskSizeGB: int

  @description('Set if the encryption at host is enabled or disabled.')
  encryptionAtHost: encryptionAtHostType

  @description('The resource id of the disk encryption set to use for the worker nodes. If it is not set disk encryption set will not be used.')
  diskEncryptionSetId: string?

  @description('The resource id of the subnet to use for the worker nodes. If it is not set it will be set by the aro module.')
  subnetId: string?
}
