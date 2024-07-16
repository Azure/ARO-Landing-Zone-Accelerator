@export()
@description('The image reference type. Contains the publisher, offer, sku, and version.')
type imageReferenceType = {
  @description('The publisher of the image.')
  publisher: string
  
  @description('The offer of the image.')
  offer: string
  
  @description('The SKU of the image.')
  sku: string

  @description('The version of the image. If not provided, the latest version will be used.')
  version: string
}

@export()
@description('The NIC configuration type. Contains the delete options, IP configurations, and NIC suffix.')
type nicConfigurationType = {
  @description('The delete options for the NIC. Can be "Delete", "Detach", or "None".')
    deleteOptions: 'Delete' | 'Detach' | 'None'
    
    @description('The list of IP configurations for the NIC.')
    ipConfigurations: ipConfigurationType[]

    @description('The suffix to append to the NIC name.')
    nicSuffix: string
  }

@export()
@description('The OS disk type. Contains the create option, delete option, and managed disk.')
type osDiskType = {
  @description('The create option for the OS disk. (Optional) Can be "Attach", "Empty", "FromImage", or null.')
  createOption: 'Attach' | 'Empty' | 'FromImage'?

  @description('The delete option for the OS disk. (Optional) Can be "Delete", "Detach", or null.')
  deleteOption: 'Delete' | 'Detach'?

  @description('The managed disk configuration for the OS disk.')
  managedDisk: managedDiskType

  @description('The size of the OS disk in GB.')
  diskSizeGB: int
}

@description('The IP configuration type. Contains the name and subnet resource id of the IP configuration.')
type ipConfigurationType = {
  @description('The name of the IP configuration.')
  name: string

  @description('The private IP address of the IP configuration.')
  subnetResourceId: string
}

@description('The managed disk type. Contains the storage account type of the managed disk.')
type managedDiskType = {
  @description('The storage account type of the managed disk.')
  storageAccountType: 'PremiumV2_LRS' | 'Premium_LRS' | 'Premium_ZRS' | 'StandardSSD_LRS' | 'StandardSSD_ZRS' | 'Standard_LRS' | 'UltraSSD_LRS' | null
}
