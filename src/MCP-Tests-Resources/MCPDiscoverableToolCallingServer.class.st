"
Test double for MCP that routes discoverable tools through tool_call and answers both response fields.
"
Class {
	#name : 'MCPDiscoverableToolCallingServer',
	#superclass : 'MCP',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'initialization' }
MCPDiscoverableToolCallingServer >> initialize [

	super initialize.
	self useContentAndStructuredContentToolResponses
]

{ #category : 'private - calling' }
MCPDiscoverableToolCallingServer >> rpcToolCall: aToolName withParams: someArguments [

	(self toolRegistry isToolAdvertisedNamed: aToolName) ifTrue: [ ^ super rpcToolCall: aToolName withParams: someArguments ].
	^ super rpcToolCall: 'tool_call' withParams: {
			  (#name -> aToolName).
			  (#arguments -> someArguments) } asDictionary
]
