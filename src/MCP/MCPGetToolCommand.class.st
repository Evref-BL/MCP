"
Returns full metadata and schemas for one catalog tool.

This command is the second step of the discoverable-tool flow: after discovery gives a candidate name, tool_get exposes the exact contract needed for a safe call.
"
Class {
	#name : 'MCPGetToolCommand',
	#superclass : 'MCPToolCatalogCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPGetToolCommand class >> tool: aTool request: aRequest [

	^ self
		  tool: aTool
		  request: aRequest
		  toolExposurePolicy: MCPToolExposurePolicy default
]

{ #category : 'executing' }
MCPGetToolCommand >> execute [

	| catalogTool |
	catalogTool := MCPToolRegistry
		               toolNamed: request toolName
		               ifAbsent: [ Error signal: 'Unknown MCP tool: ' , request toolName ]
		               usingPolicy: self toolExposurePolicy.
	^ { (#tool -> (MCPToolRegistry contractForTool: catalogTool usingPolicy: self toolExposurePolicy includeOutputSchema: false)) }
		  asDictionary
]
