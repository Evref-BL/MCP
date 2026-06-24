"
Searches the tool catalog and returns compact metadata for matching tools.

This command supports the discoverable-tool workflow: agents can search by text or group, then read a selected tool contract before invoking it.
"
Class {
	#name : 'MCPSearchToolsCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'toolExposurePolicy'
	],
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

{ #category : 'instance creation' }
MCPSearchToolsCommand class >> tool: aTool request: aRequest toolExposurePolicy: aToolExposurePolicy [

	^ self new
		  initializeTool: aTool request: aRequest;
		  toolExposurePolicy: aToolExposurePolicy;
		  yourself
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

{ #category : 'accessing' }
MCPSearchToolsCommand >> toolExposurePolicy [

	^ toolExposurePolicy ifNil: [ MCPToolExposurePolicy default ]
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> toolExposurePolicy: aToolExposurePolicy [

	toolExposurePolicy := aToolExposurePolicy ifNil: [
		                      MCPToolExposurePolicy default ]
]
