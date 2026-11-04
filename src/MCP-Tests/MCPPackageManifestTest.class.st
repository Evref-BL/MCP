"
Holds what every MCP package's manifest promises: that code written into the package is formatted with the formatter of the baseline's manifest.
"
Class {
	#name : 'MCPPackageManifestTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPPackageManifestTest >> testEveryPackageAnswersTheFormatterOfTheBaseline [
	"A package without a manifest gets the image's default formatter, and wherever that default agrees with MCP's, formatted code cannot tell the two apart. So each manifest is asked whether its formatter is the baseline's. The baseline names the packages of the running Pharo version, and a package left unloaded has nothing to format."

	| packageNames |
	packageNames := BaselineOfMCP allPackageNames select: [ :name | PackageOrganizer default hasPackage: name ].
	self denyEmpty: packageNames.
	packageNames do: [ :name |
			| manifest |
			manifest := (PackageOrganizer default packageNamed: name) packageManifestOrNil.
			self assert: manifest isNotNil description: name , ' has no manifest'.
			self
				assert: ((manifest class includesSelector: #formatter) and: [
						 (manifest class >> #formatter) referencedClasses includes: ManifestBaselineOfMCP ])
				description: manifest name , ' does not answer the formatter of ManifestBaselineOfMCP' ]
]
