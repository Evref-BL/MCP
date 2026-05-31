"
MCP tool for managing debugger session inventory.

It exposes listing, describing, forgetting, discovering external debuggers, and attaching discovered debuggers to the MCP registry.
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
MCPToolDebugSessions >> defaultDescription [

	^ 'List, describe, forget, discover, or attach Pharo DebugSession records tracked by the MCP debugger registry. Discover returns unattached open debugger candidates; attach imports one by candidateRef.'
]

{ #category : 'defaults' }
MCPToolDebugSessions >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #bug badgeIconNamed: #book) }
]

{ #category : 'defaults' }
MCPToolDebugSessions >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   stringEnumSchemaPropertyNamed: 'operation'
					   description: 'Session registry operation to perform.'
					   values: MCPDebugSessionsRequest supportedOperations
					   default: 'list').
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description:
						   'Opaque debug session identifier returned by debug_session_list, debug_capture, debug_test_run, or debug_candidate_attach.').
				  (self
					   schemaPropertyNamed: 'candidateRef'
					   type: 'string'
					   description:
						   'Opaque debugger candidate reference returned by debug_candidate_search.') };
		  required: #(  );
		  additionalProperties: false;
		  yourself
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

{ #category : 'defaults' }
MCPToolDebugSessions >> defaultTitle [

	^ 'Debug Sessions'
]

{ #category : 'private - request' }
MCPToolDebugSessions >> parsedRequestFromToolRequest: request [

	^ MCPDebugSessionsRequest fromRequest: request tool: self
]
