@export()
@description('The SKU of the key vault.')
type skuType = 'standard' | 'premium'

@export()
@description('Type definition for a secret in Key Vault')
type keyVaultSecretType = {
  @description('The name of the secret')
  name: string

  @description('The value of the secret')
  @secure()
  value: string
}

@export()
@description('The elliptic curve name.')
type curveNameType = 'P-256' | 'P-256K' | 'P-384' | 'P-521'
 
@export()
@description('The type of the key.')
type ktyType = 'EC' | 'EC-HSM' | 'RSA' | 'RSA-HSM'
 
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
}
