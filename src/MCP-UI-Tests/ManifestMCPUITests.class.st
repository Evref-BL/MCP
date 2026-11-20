"
The tests of MCP's Spec presenters.
"
Class {
	#name : 'ManifestMCPUITests',
	#superclass : 'PackageManifest',
	#category : 'MCP-UI-Tests-Manifest',
	#package : 'MCP-UI-Tests',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPUITests class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
