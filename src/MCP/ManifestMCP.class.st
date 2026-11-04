"
The MCP server: its Streamable HTTP transport, the JSON-RPC handlers, the tool registry and its schema machinery, and the catalog tools it dispatches through. A project serving tools of its own needs this package alone.
"
Class {
	#name : 'ManifestMCP',
	#superclass : 'PackageManifest',
	#category : 'MCP-Manifest',
	#package : 'MCP',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCP class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
