"
Shared implementation for focused debugger-session tools. It supports listing, describing, forgetting, discovering external debuggers, and attaching discovered debuggers to the MCP registry.
"
Class {
	#name : 'MCPToolDebugSessions',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugSessions class >> isAbstract [

	^ self = MCPToolDebugSessions
]

{ #category : 'private - execution' }
MCPToolDebugSessions >> commandForRequest: debugRequest [

	^ MCPDebugSessionsCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugSessions >> defaultOutputSchema [

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
					   'Single debug session summary for describe or attach operations.').
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
					   booleanSchemaPropertyNamed: 'forgotten'
					   description:
					   'Whether the requested session was removed from the registry.').
				  (self
					   booleanSchemaPropertyNamed: 'terminated'
					   description:
					   'Whether forgetting the session also terminated an owned captured worker process.') }
		  required: #(  )
]
