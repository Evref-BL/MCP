Class {
	#name : 'MCPToolDebugEdit',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'icons' }
MCPToolDebugEdit class >> toolIconSpec [

	^ MCPToolIconSpec baseIconNamed: #page badgeIconNamed: #edit
]

{ #category : 'defaults' }
MCPToolDebugEdit class >> toolName [

	^ 'debug-edit'
]

{ #category : 'private - execution' }
MCPToolDebugEdit >> commandForRequest: debugRequest [

	^ MCPDebugEditCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugEdit >> defaultDescription [

	^ 'Create or hot-recompile the method implied by a paused Pharo DebugSession frame, including DNU and stub repairs, and return critiques plus a refreshed debug-state snapshot.'
]

{ #category : 'defaults' }
MCPToolDebugEdit >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #page badgeIconNamed: #edit) }
]

{ #category : 'defaults' }
MCPToolDebugEdit >> defaultInputSchema [

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
						   'Optional state token to reject stale debug-edit requests.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description:
						   'Optional state-scoped frame reference returned by debug-state. Defaults to the selected top frame.').
				  (self
					   schemaPropertyNamed: 'methodSource'
					   type: 'string'
					   description:
						   'Optional replacement method source. DNU and subclass responsibility repairs can use the image default when omitted.').
				  (self
					   integerSchemaPropertyNamed: 'sourceContextLines'
					   description:
						   'Number of source context lines requested in returned state.'
					   default: 5).
				  (self
					   integerSchemaPropertyNamed: 'stackStart'
					   description:
						   'Zero-based stack frame offset for returned state.'
					   default: 0).
				  (self
					   integerSchemaPropertyNamed: 'stackLimit'
					   description:
						   'Maximum number of stack frames in returned state.'
					   default: 20).
				  (self
					   integerSchemaPropertyNamed: 'variableDepth'
					   description:
						   'Inline variable preview depth in returned state.'
					   default: 1).
				  (self
					   integerSchemaPropertyNamed: 'variableLimit'
					   description:
						   'Maximum number of variables to preview in returned state.'
					   default: 50).
				  (self
					   booleanSchemaPropertyNamed: 'includeReceiver'
					   description:
						   'Whether returned state should include the receiver scope.'
					   default: true) };
		  required: #( 'sessionId' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugEdit >> defaultName [

	^ 'debug-edit'
]

{ #category : 'defaults' }
MCPToolDebugEdit >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description: 'Debug session identifier.').
				  (self
					   schemaPropertyNamed: 'previousStateId'
					   type: 'string'
					   description: 'Debug state token before the edit.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description: 'Debug state token after the edit.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description: 'State-scoped frame reference edited.').
				  (self
					   schemaPropertyNamed: 'editKind'
					   type: 'string'
					   description:
					   'Resolved edit path, such as missingMethod or recompile.').
				  (self
					   schemaPropertyNamed: 'method'
					   type: 'object'
					   description: 'Compiled method metadata.').
				  (self
					   schemaPropertyNamed: 'critiques'
					   type: 'array'
					   description: 'Quality critiques for the compiled method.').
				  (self
					   schemaPropertyNamed: 'state'
					   type: 'object'
					   description: 'Debug-state snapshot after the edit.').
				  (self
					   schemaPropertyNamed: 'repairActions'
					   type: 'array'
					   description: 'Repair actions still available after the edit.').
				  (self
					   stringArraySchemaNamed: 'warnings'
					   description: 'Edit-specific warnings.'
					   itemDescription: 'A warning message.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Debug edit capability gates used for this response.') }
		  required:
			  #( 'sessionId' 'previousStateId' 'stateId' 'frameRef' 'editKind'
			     'method' 'critiques' 'state' 'repairActions' 'warnings'
			     'capabilities' )
]

{ #category : 'defaults' }
MCPToolDebugEdit >> defaultTitle [

	^ 'Debug Edit'
]

{ #category : 'private - data' }
MCPToolDebugEdit >> editWarnings [

	^ #( 'debug-edit compiles Smalltalk code in the running image and may mutate a suspended debug process.' )
]

{ #category : 'executing' }
MCPToolDebugEdit >> executeWithRequest: request [

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
MCPToolDebugEdit >> parsedRequestFromToolRequest: request [

	^ MCPDebugEditRequest fromRequest: request tool: self
]

{ #category : 'testing' }
MCPToolDebugEdit >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]
