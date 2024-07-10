@description('Returns the string value with a hyphen prefix if provided, otherwise returns an empty string.')
func getStringWithLeadingHyphen(value string?) string => value == null ? '' : '-${value}'

@export()
@description('Generates a name for a resource.')
func getResourceName(resourceAbreviation string, workloadName string, env string, hash string?) string => '${resourceAbreviation}-${workloadName}-${toLower(env)}${getStringWithLeadingHyphen(hash)}'

@export()
@description('Generates a name for a resource with a parent resource name.')
func getResourceNameFromParentResourceName(resourceAbreviation string, parentResourceName string) string => '${resourceAbreviation}-${parentResourceName}'
