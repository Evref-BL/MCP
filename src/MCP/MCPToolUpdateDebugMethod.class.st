"
MCP tool for debugger-driven method updates.

It creates missing methods or recompiles the selected frame method, reports critiques, and proceeds the computation only when the update is accepted.
"
Class {
	#name : 'MCPToolUpdateDebugMethod',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolUpdateDebugMethod class >> toolName [

	^ 'debug_method_update'
]

{ #category : 'private - execution' }
MCPToolUpdateDebugMethod >> commandForRequest: debugRequest [

	^ MCPUpdateDebugMethodCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolUpdateDebugMethod >> defaultDescription [

	^ 'Update the method associated with a paused Pharo DebugSession frame. Supports normal debugger-time method updates and repair flows for resumable exceptions, gates on critiques unless ignoreCritiques=true, then proceeds the computation when possible.'
]

{ #category : 'defaults' }
MCPToolUpdateDebugMethod >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #bug badgeIconNamed: #edit) }
]

{ #category : 'defaults' }
MCPToolUpdateDebugMethod >> defaultInputSchema [

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
						   'Optional state token rejecting stale debug_method_update requests.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description:
						   'Optional state-scoped frame reference returned by debug_state_get. Defaults to the selected top frame.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description:
						   'Optional replacement source. DNU and subclass responsibility repairs use the default when omitted.').
				  (self
					   booleanSchemaPropertyNamed: 'ignoreCritiques'
					   description:
						   'Proceed after successful compile even when critiques are reported.'
					   default: false).
				  (self
					   integerSchemaPropertyNamed: 'sourceContextLines'
					   description:
						   'Number of source lines requested in returned state.'
					   default: 5).
				  (self
					   integerSchemaPropertyNamed: 'stackStart'
					   description:
						   'Zero-based stack frame offset returned in state.'
					   default: 0).
				  (self
					   integerSchemaPropertyNamed: 'stackLimit'
					   description: 'Maximum stack frames returned in state.'
					   default: 20).
				  (self
					   integerSchemaPropertyNamed: 'variableDepth'
					   description:
						   'Inline variable preview depth in returned state.'
					   default: 1).
				  (self
					   integerSchemaPropertyNamed: 'variableLimit'
					   description: 'Maximum variable previews returned in state.'
					   default: 50).
				  (self
					   booleanSchemaPropertyNamed: 'includeReceiver'
					   description: 'Include receiver scope in returned state.'
					   default: true) };
		  required: #( 'sessionId' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolUpdateDebugMethod >> defaultName [

	^ 'debug_method_update'
]

{ #category : 'defaults' }
MCPToolUpdateDebugMethod >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description: 'Debug session identifier.').
				  (self
					   schemaPropertyNamed: 'previousStateId'
					   type: 'string'
					   description: 'Debug state token before the update.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description: 'Debug state token after the update/proceed cycle.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description: 'State-scoped frame reference updated.').
				  (self
					   schemaPropertyNamed: 'updateKind'
					   type: 'string'
					   description:
					   'Resolved update path, such as missingMethod or recompile.').
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
					   'Whether debug_method_update proceeded the debug process after compiling.').
				  (self
					   booleanSchemaPropertyNamed: 'blockedByCritiques'
					   description:
					   'Whether debug_method_update stopped before proceeding because critiques were reported and ignoreCritiques was false.').
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
					   'Debug-state snapshot after the update/proceed cycle, or nil when execution completed or is running.').
				  (self
					   schemaPropertyNamed: 'repairActions'
					   type: 'array'
					   description: 'Repair actions still available after the update.').
				  (self
					   stringArraySchemaNamed: 'warnings'
					   description: 'Update-specific warnings.'
					   itemDescription: 'A warning message.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Debug method update capability gates used for this response.') }
		  required:
			  #( 'sessionId' 'previousStateId' 'stateId' 'frameRef' 'updateKind'
			     'method' 'critiques' 'proceeded' 'blockedByCritiques'
			     'proceedOutcome' 'resultClassName' 'resultPrintString'
			     'timedOut' 'state' 'repairActions' 'warnings' 'capabilities' )
]

{ #category : 'defaults' }
MCPToolUpdateDebugMethod >> defaultTitle [

	^ 'Update Debug Method'
]

{ #category : 'private - request' }
MCPToolUpdateDebugMethod >> parsedRequestFromToolRequest: request [

	^ MCPUpdateDebugMethodRequest fromRequest: request tool: self
]

{ #category : 'testing' }
MCPToolUpdateDebugMethod >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]

{ #category : 'private - data' }
MCPToolUpdateDebugMethod >> updateWarnings [

	^ #( 'debug_method_update compiles Smalltalk code in the running image and may mutate or resume a suspended debug process.' )
]
