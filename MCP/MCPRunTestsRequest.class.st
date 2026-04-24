"
Parsed run-tests tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPRunTestsRequest',
	#superclass : 'Object',
	#instVars : [
		'testRequests',
		'timeoutMilliseconds'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRunTestsRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeTestRequests: (aTool testRequestsFromRequest: aRequest)
		  timeoutMilliseconds:
		  (aTool timeoutMillisecondsFromRequest: aRequest)
]

{ #category : 'initialization' }
MCPRunTestsRequest >> initializeTestRequests: aCollection timeoutMilliseconds: anInteger [

	testRequests := aCollection.
	timeoutMilliseconds := anInteger.
	^ self
]

{ #category : 'accessing' }
MCPRunTestsRequest >> testRequests [

	^ testRequests
]

{ #category : 'accessing' }
MCPRunTestsRequest >> timeoutMilliseconds [

	^ timeoutMilliseconds
]
