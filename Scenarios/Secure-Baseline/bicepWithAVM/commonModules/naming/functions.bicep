/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { resourceTypeType, locationType } from 'types.bicep'

/* -------------------------------------------------------------------------- */
/*                              PRIVATE FUNCTIONS                             */
/* -------------------------------------------------------------------------- */

@description('Returns the string value with a hyphen prefix if provided, otherwise returns an empty string.')
func getStringLeadingWithHyphen(value string?) string => value == null ? '' : '-${value!}'

@description('Returns the abbreviations object that represents all resource abbreviation.')
func getAbbreviations() object => loadJsonContent('abbreviations.json')

@description('Returns the locations object that represents all locations.')
func getShortLocations() object => loadJsonContent('locations.json')

@description('Returns the location abbreviation for the provided location. If the abbreviation is not found, returns "unknown".')
func getShortLocation(location string) string => getShortLocations()[location] ?? 'unknown'

/* -------------------------------------------------------------------------- */
/*                              PUBLIC FUNCTIONS                              */
/* -------------------------------------------------------------------------- */

@export()
@description('Returns the abbreviation for the provided resource type. If the abbreviation is not found, returns "unknown".')
func getAbbreviation(resourceType resourceTypeType) string => getAbbreviations()[resourceType] ?? 'unknown'

@export()
@description('Returns a resource name that follows the convention: {abbreviation(ResourceType)}-{lower(workload)}-{lower(environment)}-{lower(region)}-{hash}')
func getResourceName(resourceType resourceTypeType, workloadName string, env string, location locationType, postfix string?, hash string?) string => '${getAbbreviation(resourceType)}-${toLower(workloadName)}-${toLower(env)}-${getShortLocation(location)}${getStringLeadingWithHyphen(postfix)}${getStringLeadingWithHyphen(hash)}'

@export()
@description('Returns a resource name that is a concatenation of the provided strings separated by a hyphen.')
func getResourceNameFromParentResourceName(resourceType resourceTypeType, parentResourceName string, postfix string?, hash string?) string => hash == null ? '${getAbbreviation(resourceType)}-${parentResourceName}${getStringLeadingWithHyphen(postfix)}' : '${getAbbreviation(resourceType)}-${replace(parentResourceName, '-${hash!}', '')}${getStringLeadingWithHyphen(postfix)}-${hash!}'

@export()
@description('Replaces the placeholders in the provided name with the provided values.')
func replaceSubnetNamePlaceholders(name string, workloadName string, env string) string => replace(replace(name, '{workloadName}', workloadName), '{env}', toLower(env))
