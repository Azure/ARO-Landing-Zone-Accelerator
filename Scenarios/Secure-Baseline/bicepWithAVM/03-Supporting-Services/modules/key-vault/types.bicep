@export()
@description('The SKU of the key vault.')
type skuType = 'standard' | 'premium'

@export()
type keyType = {
  @description('The name of the key.')
  name: string

  @description('Determines whether or not the object is enabled. If it is not set, the object is enabled by default.')
  attributesEnabled: bool?
  
  @description('Expiry date in seconds since 1970-01-01T00:00:00Z.')
  attributesExp: int?
  
  @description('Not before date in seconds since 1970-01-01T00:00:00Z.')
  attributesNbf: int?
  
  @description('The elliptic curve name.')
  curveName: curveNameType?
  
  @description('The key size in bits. For example: 2048, 3072, or 4096 for RSA.')
  keySize: 2048 | 3072 | 4096 | null

  @description('The type of the key.')
  kty: ktyType

  @description('The key rotation policy.')
  rotationPolicy: rotationPolicyType?
}

@description('The type of the key.')
type ktyType = 'EC' | 'EC-HSM' | 'RSA' | 'RSA-HSM'

@description('The elliptic curve name.')
type curveNameType = 'P-256' | 'P-256K' | 'P-384' | 'P-521'

@description('Defines the attributes for the rotation policy')
type rotationPolicyAttributesType = {
  @description('The expiry time for the key')
  expiryTime: string
}

@description('Defines the action for a lifetime action')
type lifetimeActionActionType = {
  @description('The type of action to take')
  type: 'Rotate' | 'Notify'
}

@description('Defines the trigger for a lifetime action')
type lifetimeActionTriggerType = {
  @description('The time before expiry to trigger the action')
  timeBeforeExpiry: string
}

@description('Defines a single lifetime action')
type lifetimeActionType = {
  @description('The action to take')
  action: lifetimeActionActionType

  @description('The trigger for the action')
  trigger: lifetimeActionTriggerType
}

@description('Defines the rotation policy for a key')
type rotationPolicyType = {
  @description('The attributes of the rotation policy')
  attributes: rotationPolicyAttributesType

  @description('The lifetime actions for the rotation policy')
  lifetimeActions: lifetimeActionType[]
}
