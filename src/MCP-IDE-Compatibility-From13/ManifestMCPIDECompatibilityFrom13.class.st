"
Extensions through which MCP-IDE reads compiler errors the way Pharo 13 and later raise them: they answer MCP's own mcp* selectors from the compiler classes of those versions. The baseline loads this package from Pharo 13 on.
"
Class {
	#name : 'ManifestMCPIDECompatibilityFrom13',
	#superclass : 'PackageManifest',
	#category : 'MCP-IDE-Compatibility-From13-Manifest',
	#package : 'MCP-IDE-Compatibility-From13',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPIDECompatibilityFrom13 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
