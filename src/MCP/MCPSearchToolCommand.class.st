"
Command object used by search tools. It executes a parsed search request against its tool and returns matching entry DTO dictionaries before pagination/output shaping.
"
Class {
	#name : 'MCPSearchToolCommand',
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
MCPSearchToolCommand class >> tool: aTool request: aRequest [

	^ self new
		  tool: aTool;
		  request: aRequest;
		  yourself
]

{ #category : 'executing' }
MCPSearchToolCommand >> execute [

	^ tool queryEntriesForQueryRequest: request
]

{ #category : 'accessing' }
MCPSearchToolCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPSearchToolCommand >> request: anObject [

	request := anObject
]

{ #category : 'accessing' }
MCPSearchToolCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPSearchToolCommand >> tool: anObject [

	tool := anObject
]
