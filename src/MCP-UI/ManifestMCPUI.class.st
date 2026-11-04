"
Spec presenters on an image's MCP servers: the server list in the world menu, and what the inspector shows of one server, its dashboard, its tools and its observability.
"
Class {
	#name : 'ManifestMCPUI',
	#superclass : 'PackageManifest',
	#category : 'MCP-UI-Manifest',
	#package : 'MCP-UI',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPUI class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
