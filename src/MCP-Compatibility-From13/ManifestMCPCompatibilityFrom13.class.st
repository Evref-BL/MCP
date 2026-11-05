"
Extensions through which MCP reads compiler errors the way Pharo 13 and later raise them. MCP sends its own mcp* selectors, which Object answers with nil, and these answer them from those versions' compiler classes. The baseline loads this package from Pharo 13 on.
"
Class {
	#name : 'ManifestMCPCompatibilityFrom13',
	#superclass : 'PackageManifest',
	#category : 'MCP-Compatibility-From13-Manifest',
	#package : 'MCP-Compatibility-From13',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPCompatibilityFrom13 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
