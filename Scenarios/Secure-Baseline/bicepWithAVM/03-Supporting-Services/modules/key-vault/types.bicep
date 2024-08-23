@export()
@description('The SKU of the key vault.')
type skuType = 'standard' | 'premium'

@export()
@description('The properties of the key vault.')
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
  curveName: 'P-256' | 'P-256K' | 'P-384' | 'P-521'?
  
  @description('The key size in bits. For example: 2048, 3072, or 4096 for RSA.')
  keySize: 2048 | 3072 | 4096 | null

  @description('The type of the key.')
  kty: 'EC' | 'EC-HSM' | 'RSA' | 'RSA-HSM'

  @description('The key rotation policy.')
  rotationPolicy: {
    @description('The attributes of the rotation policy.')
    attributes: {
      @description('The expiry time for the new key version. It should be in ISO8601 format. Eg: \'P90D\', \'P1Y\'.')
      expiryTime: string
    }

    @description('The lifetime actions for the rotation policy.')
    lifetimeActions: {
      @description('The action to take.')
      action: {
        @description('The type of action to take.')
        type: 'Rotate' | 'Notify'
      }

      @description('The trigger for the action.')
      trigger: {
        @description('The time before expiry to trigger the action.')
        timeBeforeExpiry: string
      }
    }[]
  }?
}

@export()
@description('The properties of the secret.')
type secretType = {
  @description('The resource name.')
  @maxLength(127)
  @minLength(1)
  name: string
  
  @description('The value of the secret. NOTE: "value" will never be returned from the service, as APIs using this model are is intended for internal use in ARM deployments. Users should use the data-plane REST service for interaction with vault secrets.')
  value: string

  @description('The attributes of the secret (Optional).')
  attributes: {
    @description('Determines whether the object is enabled (Optional).')
    enabled: bool?
    
    @description('Expiry date in seconds since 1970-01-01T00:00:00Z (Optional).')
    nbf: int?

    @description('Not before date in seconds since 1970-01-01T00:00:00Z (Optional).')
    exp: int?
  }?

  @description('The content type of the secret (Optional).')
  contentType: string?

  @description('The tags of the secret (Optional).')
  tags: object?

  @description('The role assignments for the secret (Optional).')
  roleAssignments: {
    @description('The role assignment properties.')
    properties: {
      @description('The role definition ID.')
      roleDefinitionId: string

      @description('The principal ID.')
      principalId: string

      @description('The description of the role assignment (Optional).')
      description: string?

      @description('The principal type of the assigned principal ID (Optional).')
      principalType: string?

      @description('The condition of the role assignment (Optional).')
      condition: string?

      @description('Version of the condition (Optional). Currently the only accepted value is "2.0".')
      conditionVersion: string?

      @description('Id of the delegated managed identity resource	(Optional).')
      delegatedManagedIdentityResourceId: string?
    }
  }[]?
}
