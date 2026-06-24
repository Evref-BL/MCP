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

{ #category : 'metadata' }
MCPToolDebugSessionOperation >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolDebugSessionOperation >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'sessions'
					   type: 'array'
					   description: 'Registered debug session summaries.').
				  (self
					   schemaPropertyNamed: 'candidates'
					   type: 'array'
					   description: 'Unattached debugger candidates.').
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description:
					   'Total number of returned sessions or candidates.').
				  (self
					   schemaPropertyNamed: 'session'
					   type: 'object'
					   description:
					   'Single debug session summary for get or attach operations.').
				  (self
					   schemaPropertyNamed: 'state'
					   type: 'object'
					   description:
					   'Debug state snapshot returned after attaching a candidate.').
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description: 'Identifier of the affected debug session.').
				  (self
					   schemaPropertyNamed: 'candidateRef'
					   type: 'string'
					   description: 'Identifier of the affected debugger candidate.').
				  (self
					   booleanSchemaPropertyNamed: 'attached'
					   description:
					   'Whether attach associated the candidate with an MCP debug session.').
				  (self
					   booleanSchemaPropertyNamed: 'alreadyAttached'
					   description:
					   'Whether attach returned an existing MCP session for the candidate.').
				  (self
					   booleanSchemaPropertyNamed: 'removed'
					   description:
					   'Whether the requested session was removed from the registry.').
				  (self
					   booleanSchemaPropertyNamed: 'terminated'
					   description:
					   'Whether removing the session also terminated an owned captured worker process.') }
		  required: #(  )
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> candidateRefSchemaProperty [

	^ self
		  schemaPropertyNamed: 'candidateRef'
		  type: 'string'
		  description:
		  'Opaque debugger candidate reference returned by debug_candidate_search.'
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

	^ MCPDebugSessionsRequest
		  fromRequest: request
		  tool: self
		  operation: self actionName
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> requiredInputProperties [

	^ self sessionToolSpec
		  at: #requiredProperties
		  ifAbsent: [ #(  ) ]
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> sessionIdSchemaProperty [

	^ self
		  schemaPropertyNamed: 'sessionId'
		  type: 'string'
		  description:
		  'Opaque debug session identifier returned by debug_session_list, debug_capture, debug_test_run, or debug_candidate_attach.'
]

{ #category : 'private - specs' }
MCPToolDebugSessionOperation >> sessionToolSpec [

	self subclassResponsibility
]

{ #category : 'metadata' }
MCPToolDebugSessionOperation >> title [

	^ self sessionToolSpec at: #title
]
