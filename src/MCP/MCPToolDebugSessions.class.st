"
MCP tool for managing debugger session inventory.

It exposes listing, describing, forgetting, discovering external debuggers, and attaching discovered debuggers to the MCP registry.
"
Class {
	#name : 'MCPToolDebugSessions',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'icons' }
MCPToolDebugSessions class >> toolIconSpec [

	^ MCPToolIconSpec baseIconNamed: #open badgeIconNamed: #inspect
]

{ #category : 'defaults' }
MCPToolDebugSessions class >> toolName [

	^ 'debug-sessions'
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

	^ { (self pngCompositeBaseIconNamed: #open badgeIconNamed: #inspect) }
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
						   'Opaque debug session identifier returned by debug-sessions.').
				  (self
					   schemaPropertyNamed: 'candidateRef'
					   type: 'string'
					   description:
						   'Opaque debugger candidate reference returned by debug-sessions discover.') };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugSessions >> defaultName [

	^ 'debug-sessions'
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
					   description:
					   'Unattached debugger candidates ordered from newest to oldest.').
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

{ #category : 'executing' }
MCPToolDebugSessions >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :debugRequest |
				  | commandResult |
				  commandResult := (self commandForRequest: debugRequest) execute.
				  commandResult isError
					  ifTrue: [
							  self
								  errorResultText: commandResult summary
								  details: commandResult errorDetails ]
					  ifFalse: [
							  self
								  successResultText: commandResult summary
								  data: commandResult data
								  warnings: commandResult warnings ] ]
		  onError: [ :error :ignored |
				  self
					  errorResultText: (error messageText ifNil: [ error asString ])
					  details: ((error isKindOf: MCPCommandError)
							   ifTrue: [ error structuredDetails ]
							   ifFalse: [ self errorDetailsFor: error ]) ]
]

{ #category : 'private - request' }
MCPToolDebugSessions >> parsedRequestFromToolRequest: request [

	^ MCPDebugSessionsRequest fromRequest: request tool: self
]
