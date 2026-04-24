"
Command object used by query tools. It executes a parsed query request against its tool and returns the matching entry DTO dictionaries before pagination/output shaping.
"
Class {
	#name : 'MCPQueryToolCommand',
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
MCPQueryToolCommand class >> tool: aTool request: aRequest [

	^ self new
		  tool: aTool;
		  request: aRequest;
		  yourself
]

{ #category : 'executing' }
MCPQueryToolCommand >> execute [

	^ tool queryEntriesForQuerySpec: request
]

{ #category : 'accessing' }
MCPQueryToolCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPQueryToolCommand >> request: anObject [

	request := anObject
]

{ #category : 'accessing' }
MCPQueryToolCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPQueryToolCommand >> tool: anObject [

	tool := anObject
]
