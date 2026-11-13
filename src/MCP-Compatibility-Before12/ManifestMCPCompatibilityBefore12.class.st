"
What MCP does the way Pharo 10 and 11 let it, under the selectors MCP-Compatibility-From12 answers from Pharo 12 on, and the mcp* selectors answered from the classes of those versions. The baseline loads this package before Pharo 12 only.
"
Class {
	#name : 'ManifestMCPCompatibilityBefore12',
	#superclass : 'PackageManifest',
	#category : 'MCP-Compatibility-Before12-Manifest',
	#package : 'MCP-Compatibility-Before12',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPCompatibilityBefore12 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
