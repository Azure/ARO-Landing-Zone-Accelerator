/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { resourceTypeType, locationType } from 'types.bicep'

/* -------------------------------------------------------------------------- */
/*                              PRIVATE FUNCTIONS                             */
/* -------------------------------------------------------------------------- */

@description('Returns the string value with a hyphen prefix if provided, otherwise returns an empty string.')
func getStringLeadingWithHyphen(value string?) string => empty(value) ? '' : '-${value!}'

@description('Returns the abbreviations object that represents all resource abbreviation.')
func getAbbreviations() object => loadJsonContent('abbreviations.json')

@description('Returns the abbreviation for the provided resource type. If the abbreviation is not found, returns "unknown".')
func getAbbreviation(resourceType resourceTypeType) string => getAbbreviations()[resourceType] ?? 'unknown'

@description('Returns the locations object that represents all locations.')
func getShortLocations() object => loadJsonContent('locations.json')

@description('Returns the location abbreviation for the provided location. If the abbreviation is not found, returns "unknown".')
func getShortLocation(location string) string => getShortLocations()[location] ?? 'unknown'

@description('Returns the length of the provided string. If the string is null, returns 0.')
func getStringLength(value string?) int => value == null ? 0 : length(value!)

@description('Returns a positive integer or zero based on the provided value.')
func getPositiveOrZeroInt(value int) int => value < 0 ? 0 : value

@description('Returns the remaining length based on the provided maximum length and the lenghts to remove. If the remaining length is negative, returns 0.')
func getRemainingLength(maxLength int, lenghts int[]) int => getPositiveOrZeroInt(maxLength - sys.reduce(lenghts, 0, (current, next) => current + next))

@description('Returns the remaining length of the resource name based on the provided parameters. If the hash is not provided, it used `uniqueStringSize` instead.')
func getRemainingLengthOfResource(maxLength int, abbreviation string, workloadName string, env string, location locationType, postfix string?, hash string?, uniqueStringSize int) int => getRemainingLength(maxLength, [getStringLength(abbreviation), getStringLength(workloadName), getStringLength(env), getStringLength(getShortLocation(location)), getStringLength(postfix), hash == null ? uniqueStringSize : getStringLength(hash)])

@description('Returns the hash if provided, otherwise returns a unique string based on the provided array of strings, limited to the provided length.')
func getHashOrUniqueString(hash string?, arrayForUniqueString string[]?, uniqueStringLength int) string => hash ?? take(uniqueString(join(arrayForUniqueString!, '_')), uniqueStringLength)

/* -------------------------------------------------------------------------- */
/*                              PUBLIC FUNCTIONS                              */
/* -------------------------------------------------------------------------- */

@export()
@description('Returns a resource name that follows the convention: <resource-type-abbreviation>-<workload-name>-<lower-case-env>-<location-short>[<postfix>][<hash>].')
func getResourceName(resourceType resourceTypeType, workloadName string, env string, location locationType, postfix string?, hash string?) string => '${getAbbreviation(resourceType)}-${toLower(workloadName)}-${toLower(env)}-${getShortLocation(location)}${getStringLeadingWithHyphen(postfix)}${getStringLeadingWithHyphen(hash)}'

@export()
@description('Returns a unique global name that follows the convention: <resource-type-abbreviation><workload-name-limited-to-remaing-length><lower-case-env><location-short>[<postfix>][<hash-or-unique-string>]. The name is limited to maxLength and can include dashes based on allowDashes parameter.')
func getUniqueGlobalName(resourceType resourceTypeType, workloadName string, env string, location locationType, postfix string?, hash string?, arrayForUniqueString string[]?, uniqueStringLength int, maxLength int, allowDashes bool) string => take(joinNameParts(getNameParts(resourceType, allowDashes ? workloadName : replace(workloadName, '-', ''), env, location, postfix, hash, arrayForUniqueString, uniqueStringLength, maxLength), allowDashes), maxLength)

@description('Returns an array of name parts for the unique global name.')
func getNameParts(resourceType resourceTypeType, workloadName string, env string, location locationType, postfix string?, hash string?, arrayForUniqueString string[]?, uniqueStringLength int, maxLength int) array => [
  getAbbreviation(resourceType)
  take(toLower(workloadName), getRemainingLengthOfResource(maxLength, getAbbreviation(resourceType), workloadName, env, location, postfix, hash, uniqueStringLength))
  toLower(env)
  getShortLocation(location)
  toLower(postfix ?? '')
  getHashOrUniqueString(hash, arrayForUniqueString, uniqueStringLength)
]

@description('Joins the array of name parts, optionally with dashes, filtering out empty strings.')
func joinNameParts(parts array, useDashes bool) string => useDashes ? join(filter(parts, part => !empty(part)), '-') : join(filter(parts, part => !empty(part)), '')

@export()
@description('Returns a resource name that is a concatenation of the provided strings separated by a hyphen. If the hash is provided, it is always added to the end of the resource name.')
func getResourceNameFromParentResourceName(resourceType resourceTypeType, parentResourceName string, postfix string?, hash string?) string => hash == null ? '${getAbbreviation(resourceType)}-${parentResourceName}${getStringLeadingWithHyphen(postfix)}' : '${getAbbreviation(resourceType)}-${replace(parentResourceName, '-${hash!}', '')}${getStringLeadingWithHyphen(postfix)}-${hash!}'
