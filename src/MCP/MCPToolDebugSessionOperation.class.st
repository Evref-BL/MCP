"
Shared implementation for debugger-session operation tools.

It defines per-tool debugger-session inputs for listing, getting, removing, discovering external debuggers, and attaching discovered debuggers to the MCP registry.
"
Class {
	#name : 'MCPToolDebugSessionOperation',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugSessionOperation class >> isAbstract [

	^ self = MCPToolDebugSessionOperation
]

{ #category : 'private - actions' }
MCPToolDebugSessionOperation >> actionName [

	^ self sessionToolSpec at: #action
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> candidateRefSchemaProperty [

	^ self
		  schemaPropertyNamed: 'candidateRef'
		  type: 'string'
		  description: 'Opaque debugger candidate reference returned by debug_candidate_search.'
]

{ #category : 'private - execution' }
MCPToolDebugSessionOperation >> commandForRequest: debugRequest [

	^ MCPDebugSessionsCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugSessionOperation >> description [

	^ self sessionToolSpec at: #description
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> inputProperties [

	^ self sessionToolSpec at: #inputProperties ifAbsent: [ #(  ) ]
]

{ #category : 'private - request' }
MCPToolDebugSessionOperation >> parsedRequestFromToolRequest: request [

	^ MCPDebugSessionsRequest fromRequest: request tool: self operation: self actionName
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> requiredInputProperties [

	^ self sessionToolSpec at: #requiredProperties ifAbsent: [ #(  ) ]
]

{ #category : 'private - specs' }
MCPToolDebugSessionOperation >> sessionToolSpec [

	self subclassResponsibility
]

{ #category : 'metadata' }
MCPToolDebugSessionOperation >> title [

	^ self sessionToolSpec at: #title
]
