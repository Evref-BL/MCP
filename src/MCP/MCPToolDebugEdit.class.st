"
MCP tool for debugger-driven method editing.

It creates missing methods or recompiles the selected frame method, reports critiques, and proceeds the computation only when the edit is accepted.
"
Class {
	#name : 'MCPToolDebugEdit',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'icons' }
MCPToolDebugEdit class >> toolIconSpec [

	^ MCPToolIconSpec baseIconNamed: #bug badgeIconNamed: #edit
]

{ #category : 'defaults' }
MCPToolDebugEdit class >> toolName [

	^ 'debug_method_repair'
]

{ #category : 'private - execution' }
MCPToolDebugEdit >> commandForRequest: debugRequest [

	^ MCPDebugEditCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugEdit >> defaultDescription [

	^ 'Create or hot-recompile the method implied by a paused Pharo DebugSession frame, gate on critiques unless ignoreCritiques=true, then proceed the repaired computation when possible.'
]

{ #category : 'defaults' }
MCPToolDebugEdit >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #bug badgeIconNamed: #edit) }
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
						   'Opaque debug session identifier returned by debug_session_list, debug_capture, debug_test_run, or debug_candidate_attach.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description:
						   'Optional state token to reject stale debug_method_repair requests.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description:
						   'Optional state-scoped frame reference returned by debug_state_get. Defaults to the selected top frame.').
				  (self
					   schemaPropertyNamed: 'methodSource'
					   type: 'string'
					   description:
						   'Optional replacement method source. DNU and subclass responsibility repairs can use the image default when omitted.').
				  (self
					   booleanSchemaPropertyNamed: 'ignoreCritiques'
					   description:
						   'Whether debug_method_repair should proceed after a successful compile even when method critiques are reported.'
					   default: false).
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

	^ 'debug_method_repair'
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
					   description: 'Debug state token after the edit/proceed cycle.').
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
					   booleanSchemaPropertyNamed: 'proceeded'
					   description:
					   'Whether debug_method_repair proceeded the debug process after compiling.').
				  (self
					   booleanSchemaPropertyNamed: 'blockedByCritiques'
					   description:
					   'Whether debug_method_repair stopped before proceeding because critiques were reported and ignoreCritiques was false.').
				  (self
					   schemaPropertyNamed: 'proceedOutcome'
					   type: 'string'
					   description:
					   'Proceed result such as completed, paused, running, timedOut, unavailable, or blockedByCritiques.').
				  (self
					   schemaPropertyNamed: 'resultClassName'
					   type: 'string'
					   description:
					   'Class name of the completed proceed result, or nil when no result is available.').
				  (self
					   schemaPropertyNamed: 'resultPrintString'
					   type: 'string'
					   description:
					   'Bounded printString of the completed proceed result, or nil when no result is available.').
				  (self
					   booleanSchemaPropertyNamed: 'timedOut'
					   description: 'Whether proceeding timed out.').
				  (self
					   schemaPropertyNamed: 'state'
					   type: 'object'
					   description:
					   'Debug-state snapshot after the edit/proceed cycle, or nil when execution completed or is running.').
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
			     'method' 'critiques' 'proceeded' 'blockedByCritiques'
			     'proceedOutcome' 'resultClassName' 'resultPrintString'
			     'timedOut' 'state' 'repairActions' 'warnings' 'capabilities' )
]

{ #category : 'defaults' }
MCPToolDebugEdit >> defaultTitle [

	^ 'Debug Edit'
]

{ #category : 'private - data' }
MCPToolDebugEdit >> editWarnings [

	^ #( 'debug_method_repair compiles Smalltalk code in the running image and may mutate or resume a suspended debug process.' )
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
