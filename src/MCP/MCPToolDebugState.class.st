Class {
	#name : 'MCPToolDebugState',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'icons' }
MCPToolDebugState class >> toolIconSpec [

	^ MCPToolIconSpec baseIconNamed: #page badgeIconNamed: #inspect
]

{ #category : 'defaults' }
MCPToolDebugState class >> toolName [

	^ 'debug-state'
]

{ #category : 'private - execution' }
MCPToolDebugState >> commandForRequest: debugRequest [

	^ MCPDebugStateCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugState >> defaultDescription [

	^ 'Return a composite snapshot of one Pharo DebugSession, including state-scoped frame and variable references, selected source context, stack, and shallow scope previews.'
]

{ #category : 'defaults' }
MCPToolDebugState >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #page badgeIconNamed: #inspect) }
]

{ #category : 'defaults' }
MCPToolDebugState >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description:
						   'Opaque debug session identifier returned by debug-sessions.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description:
						   'Optional state token to reject stale frame and variable references.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description:
						   'Optional state-scoped frame reference to select.').
				  (self
					   integerSchemaPropertyNamed: 'sourceContextLines'
					   description:
						   'Number of source context lines requested around the selected expression.'
					   default: 5).
				  (self
					   integerSchemaPropertyNamed: 'stackStart'
					   description: 'Zero-based stack frame offset.'
					   default: 0).
				  (self
					   integerSchemaPropertyNamed: 'stackLimit'
					   description: 'Maximum number of stack frames to return.'
					   default: 20).
				  (self
					   integerSchemaPropertyNamed: 'variableDepth'
					   description: 'Requested inline variable preview depth.'
					   default: 1).
				  (self
					   integerSchemaPropertyNamed: 'variableLimit'
					   description:
						   'Maximum number of variables to preview in each scope.'
					   default: 50).
				  (self
					   booleanSchemaPropertyNamed: 'includeReceiver'
					   description: 'Whether to include the receiver scope.'
					   default: true) };
		  required: #( 'sessionId' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugState >> defaultName [

	^ 'debug-state'
]

{ #category : 'defaults' }
MCPToolDebugState >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description: 'Debug session identifier.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description: 'Current debug state token.').
				  (self
					   schemaPropertyNamed: 'status'
					   type: 'string'
					   description: 'Current debug session status.').
				  (self
					   schemaPropertyNamed: 'reason'
					   type: 'string'
					   description: 'Reason the debug session is stopped or tracked.').
				  (self
					   schemaPropertyNamed: 'exception'
					   type: 'object'
					   description:
					   'Exception associated with the debug session when available.').
				  (self
					   schemaPropertyNamed: 'location'
					   type: 'object'
					   description: 'Selected execution location.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'object'
					   description: 'Source context for the selected frame.').
				  (self
					   schemaPropertyNamed: 'selectedFrame'
					   type: 'object'
					   description: 'Selected stack frame.').
				  (self
					   schemaPropertyNamed: 'scopes'
					   type: 'array'
					   description:
					   'State-scoped variable scopes for the selected frame.').
				  (self
					   schemaPropertyNamed: 'callStack'
					   type: 'array'
					   description: 'Visible call stack frames.').
				  (self
					   integerSchemaPropertyNamed: 'stackStart'
					   description: 'Zero-based stack offset used for the response.').
				  (self
					   integerSchemaPropertyNamed: 'stackLimit'
					   description: 'Stack frame limit used for the response.').
				  (self
					   integerSchemaPropertyNamed: 'totalFrames'
					   description: 'Number of stack frames known to this snapshot.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Debugger feature gates available for this session.').
				  (self
					   stringArraySchemaNamed: 'warnings'
					   description: 'Snapshot-specific warnings.'
					   itemDescription: 'A warning message.') }
		  required:
			  #( 'sessionId' 'stateId' 'status' 'callStack' 'capabilities'
			     'warnings' )
]

{ #category : 'defaults' }
MCPToolDebugState >> defaultTitle [

	^ 'Debug State'
]

{ #category : 'executing' }
MCPToolDebugState >> executeWithRequest: request [

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
MCPToolDebugState >> parsedRequestFromToolRequest: request [

	^ MCPDebugStateRequest fromRequest: request tool: self
]
