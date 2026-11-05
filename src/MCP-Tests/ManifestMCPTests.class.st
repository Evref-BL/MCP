"
The tests of the MCP server and its image tools. The classes they act on live in the MCP-Tests-Resources packages, and a class a test generates goes into MCP-Tests-Generated, outside the versioned packages.
"
Class {
	#name : 'ManifestMCPTests',
	#superclass : 'PackageManifest',
	#category : 'MCP-Tests-Manifest',
	#package : 'MCP-Tests',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPTests class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
