"
Searches the tool catalog and returns compact metadata for matching tools.

This command supports the discoverable-tool workflow: agents can search by text or group, then read a selected tool contract before invoking it.
"
Class {
	#name : 'MCPSearchToolsCommand',
	#superclass : 'MCPToolCatalogCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPSearchToolsCommand class >> tool: aTool request: aRequest [

	^ self
		  tool: aTool
		  request: aRequest
		  toolExposurePolicy: MCPToolExposurePolicy default
]

{ #category : 'executing' }
MCPSearchToolsCommand >> execute [

	| tools |
	tools := MCPToolRegistry
		         toolsMatchingQuery: request query
		         group: request group
		         limit: request limit
		         usingPolicy: self toolExposurePolicy.
	^ { (#tools -> (tools collect: [ :each |
			    MCPToolRegistry
				    searchMetadataForTool: each
				    usingPolicy: self toolExposurePolicy ]) asArray) }
		  asDictionary
]
