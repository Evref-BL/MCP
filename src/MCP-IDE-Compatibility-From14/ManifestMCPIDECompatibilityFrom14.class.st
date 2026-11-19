"
Extensions through which MCP-IDE reads compilation errors the way Pharo 14 and later raise them, carrying their compilation result. Like those of MCP-IDE-Compatibility-From13, they answer MCP's own mcp* selectors. The baseline loads this package from Pharo 14 on.
"
Class {
	#name : 'ManifestMCPIDECompatibilityFrom14',
	#superclass : 'PackageManifest',
	#category : 'MCP-IDE-Compatibility-From14-Manifest',
	#package : 'MCP-IDE-Compatibility-From14',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPIDECompatibilityFrom14 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
