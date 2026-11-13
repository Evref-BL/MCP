"
What MCP-IDE does the way Pharo 12 and later let it: the methods that reach classes and messages earlier versions do not have, and the mcp* selectors answered from those versions' classes. MCP-IDE-Compatibility-Before12 has the same selectors for Pharo 10 and 11. The baseline loads this package from Pharo 12 on.
"
Class {
	#name : 'ManifestMCPIDECompatibilityFrom12',
	#superclass : 'PackageManifest',
	#category : 'MCP-IDE-Compatibility-From12-Manifest',
	#package : 'MCP-IDE-Compatibility-From12',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPIDECompatibilityFrom12 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
