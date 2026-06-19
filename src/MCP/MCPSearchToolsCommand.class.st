"
Searches the tool catalog and returns compact metadata for matching tools.

This command supports the discoverable-tool workflow: agents can search by text or group, then read a selected tool contract before invoking it.
"
Class {
	#name : 'MCPSearchToolsCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPSearchToolsCommand class >> tool: aTool request: aRequest [

	^ self new
		  tool: aTool;
		  request: aRequest;
		  yourself
]

{ #category : 'executing' }
MCPSearchToolsCommand >> execute [

	| tools |
	tools := MCPToolRegistry
		         toolsMatchingQuery: request query
		         group: request group
		         limit: request limit
		         usingPolicy: tool toolExposurePolicy.
	^ { (#tools -> (tools collect: [ :each |
			    MCPToolRegistry
				    searchMetadataForTool: each
				    usingPolicy: tool toolExposurePolicy ]) asArray) }
		  asDictionary
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> request: anObject [

	request := anObject
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> tool: anObject [

	tool := anObject
]
