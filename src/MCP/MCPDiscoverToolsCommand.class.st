Class {
	#name : 'MCPDiscoverToolsCommand',
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
MCPDiscoverToolsCommand class >> tool: aTool request: aRequest [

	^ self new
		  tool: aTool;
		  request: aRequest;
		  yourself
]

{ #category : 'executing' }
MCPDiscoverToolsCommand >> execute [

	| tools |
	tools := MCPToolRegistry
		         toolsMatchingQuery: request query
		         group: request group
		         includeStatic: request includeStatic
		         limit: request limit.
	^ {
		  (#tools
		   ->
			   (tools collect: [ :each | MCPToolRegistry metadataForTool: each ])
				   asArray).
		  (#totalCount -> tools size).
		  (#query -> request query).
		  (#group -> request group).
		  (#includeStatic -> request includeStatic) } asDictionary
]

{ #category : 'accessing' }
MCPDiscoverToolsCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPDiscoverToolsCommand >> request: anObject [

	request := anObject
]

{ #category : 'accessing' }
MCPDiscoverToolsCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPDiscoverToolsCommand >> tool: anObject [

	tool := anObject
]
