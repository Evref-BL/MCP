"
Extensions through which MCP reads compilation errors the way Pharo 14 and later raise them, carrying their compilation result. Like those of MCP-Compatibility-From13, they answer MCP's own mcp* selectors. The baseline loads this package from Pharo 14 on.
"
Class {
	#name : 'ManifestMCPCompatibilityFrom14',
	#superclass : 'PackageManifest',
	#category : 'MCP-Compatibility-From14-Manifest',
	#package : 'MCP-Compatibility-From14',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPCompatibilityFrom14 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
