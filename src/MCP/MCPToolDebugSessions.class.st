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

	^ 'List, describe, or forget Pharo DebugSession records tracked by the MCP debugger registry. Session identifiers are opaque and local to the running image.'
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
						   'Opaque debug session identifier returned by debug-sessions.') };
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
					   integerSchemaPropertyNamed: 'totalCount'
					   description:
					   'Total number of registered debug sessions returned.').
				  (self
					   schemaPropertyNamed: 'session'
					   type: 'object'
					   description:
					   'Single debug session summary for describe operations.').
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description: 'Identifier of the affected debug session.').
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
