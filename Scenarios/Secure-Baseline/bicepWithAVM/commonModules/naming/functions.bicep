/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { resourceTypeType, locationType } from 'types.bicep'

/* -------------------------------------------------------------------------- */
/*                              PRIVATE FUNCTIONS                             */
/* -------------------------------------------------------------------------- */

@description('Returns a string that is the concatenation of the provided strings, separated by the provided separator.')
func arrayToString(stringArray string[], separator string?) string => join(stringArray, separator ?? '_')

@description('Returns the sum of all the integers in the provided array.')
func sumIntegers(integers int[]) int => reduce(integers, 0, (current, next) => current + next)

@description('Returns the remaining size after removing the provided sizes from the total size.')
func getRemainingSize(totalSize int, sizesToRemove int[]) int => (totalSize - sumIntegers(sizesToRemove)) < 0 ? 0 : (totalSize - sumIntegers(sizesToRemove))

@description('Returns the remaining size for the prefix and the workload name after removing the size of the environment, the hash, the postfix, and the abbreviation.')
func getResourceRemainingSize(totalSize int, environmentSize int, hashSize int, postfixSize int, abbreviationSize int) int => getRemainingSize(totalSize, [environmentSize, hashSize, postfixSize, abbreviationSize])

@description('Returns the size of the provided string. If the string is null, returns 0. If addHyphen is true, adds 1 to the size.')
func getSizeOfString(value string?, addHyphen bool) int => value == null ? 0 : length(value!) + (addHyphen ? 1 : 0)

@description('Returns the size if provided, otherwise returns 5.')
func getSizeOrDefault(size int?) int => size ?? 5

@description('Returns a unique string based on the provided strings.')
func getUniqueString(fromStrings string[], size int?) string => take(uniqueString(arrayToString(fromStrings, null)), getSizeOrDefault(size))

@description('Returns the string value with a hyphen prefix if provided, otherwise returns an empty string.')
func getStringValueWithHyphen(value string?) string => value == null ? '' : '-${value!}'

@description('Returns the string value if provided limited to the given size or the default size, otherwise returns an empty string.')
func getStringValueOfMaxSize(value string?, size int?) string => value == null ? '' : take(value!, getSizeOrDefault(size))

@description('Returns a hash if provided, otherwise returns a unique string based on the provided strings.')
func getHashOrUniqueString(hash string?, fromStrings string[]?, size int?) string => hash ?? getUniqueString(fromStrings!, size)

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
func getResourceName(resourceType resourceTypeType, workloadName string, env string, location locationType, postfix string?, hash string?) string => '${getAbbreviation(resourceType)}-${toLower(workloadName)}-${toLower(env)}-${getShortLocation(location)}${getStringValueWithHyphen(postfix)}${getStringValueWithHyphen(hash)}'

@export()
@description('Returns a resource name that is a concatenation of the provided strings separated by a hyphen.')
func getResourceNameFromParentResourceName(resourceType resourceTypeType, parentResourceName string, postfix string?, hash string?) string => hash == null ? '${getAbbreviation(resourceType)}-${parentResourceName}${getStringValueWithHyphen(postfix)}' : '${getAbbreviation(resourceType)}-${replace(parentResourceName, '-${hash!}', '')}${getStringValueWithHyphen(postfix)}-${hash!}'
