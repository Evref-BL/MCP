"
What MCP does the way Pharo 12 and later let it, under the selectors MCP-Compatibility-Before12 answers for Pharo 10 and 11. The baseline loads this package from Pharo 12 on.
"
Class {
	#name : 'ManifestMCPCompatibilityFrom12',
	#superclass : 'PackageManifest',
	#category : 'MCP-Compatibility-From12-Manifest',
	#package : 'MCP-Compatibility-From12',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPCompatibilityFrom12 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
