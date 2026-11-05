"
The Metacello baseline of MCP: its packages, what they depend on, and the groups a project loads them by. The formatter here is MCP's: every other MCP package's manifest answers it rather than state its own.
"
Class {
	#name : 'ManifestBaselineOfMCP',
	#superclass : 'PackageManifest',
	#category : 'BaselineOfMCP-Manifest',
	#package : 'BaselineOfMCP',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestBaselineOfMCP class >> formatter [

	^ EFFormatter new installNewContext: (EFContext new
			   maxLineLength: 130;
			   numberOfNewLinesAfterMethodSignatureWithMethodComment: 1)
]
