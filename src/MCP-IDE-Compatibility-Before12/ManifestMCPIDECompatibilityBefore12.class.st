"
What MCP-IDE does the way Pharo 10 and 11 let it, under the selectors MCP-IDE-Compatibility-From12 answers from Pharo 12 on: the methods that reach the classes and messages those versions have instead, and the mcp* selectors answered from their classes. The baseline loads this package before Pharo 12 only.
"
Class {
	#name : 'ManifestMCPIDECompatibilityBefore12',
	#superclass : 'PackageManifest',
	#category : 'MCP-IDE-Compatibility-Before12-Manifest',
	#package : 'MCP-IDE-Compatibility-Before12',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPIDECompatibilityBefore12 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
