"
The image tools an MCP client works through: classes, methods, packages, tests, critiques, repositories, change history and debugging. Loading this package is all it takes for the server to catalog them.
"
Class {
	#name : 'ManifestMCPIDE',
	#superclass : 'PackageManifest',
	#category : 'MCP-IDE-Manifest',
	#package : 'MCP-IDE',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPIDE class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
