"
The classes MCP's tests act on: targets the image tools read and rewrite, test doubles, and fixtures.
"
Class {
	#name : 'ManifestMCPTestsResources',
	#superclass : 'PackageManifest',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'formatting' }
ManifestMCPTestsResources class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
