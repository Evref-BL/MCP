"
MCP tool for conventional debugger control actions.

It exposes resume, terminate, restart, and stepping through a single consolidated contract, returning updated state when control pauses again.
"
Class {
	#name : 'MCPToolDebugControl',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugControl class >> isAbstract [

	^ self = MCPToolDebugControl
]

{ #category : 'icons' }
MCPToolDebugControl class >> toolIconSpec [

	^ MCPToolIconSpec baseIconNamed: #bug badgeIconNamed: #into
]

{ #category : 'defaults' }
MCPToolDebugControl class >> toolName [

	^ 'debug_session_control_operation'
]

{ #category : 'private - execution' }
MCPToolDebugControl >> commandForRequest: debugRequest [

	^ MCPDebugControlCommand tool: self request: debugRequest
]

{ #category : 'private' }
MCPToolDebugControl >> controlFailureMessageFor: anError operation: operationName [

	| message |
	message := anError messageText
		           ifNil: [ anError asString ]
		           ifNotNil: [ :text | text asString ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Debug control ';
				  nextPutAll: operationName asString;
				  nextPutAll: ' failed (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: message.
			  anError signalerContext ifNotNil: [ :context |
					  stream
						  nextPutAll: ' Signaler context: ';
						  nextPutAll: context printString ] ]
]

{ #category : 'defaults' }
MCPToolDebugControl >> defaultDescription [

	^ 'Apply one conventional control action to a tracked Pharo DebugSession, invalidate stale state-scoped refs, and optionally return the post-action debug_state_get snapshot.'
]

{ #category : 'defaults' }
MCPToolDebugControl >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #bug badgeIconNamed: #into) }
]

{ #category : 'defaults' }
MCPToolDebugControl >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description:
						   'Opaque debug session identifier returned by debug_session_list, debug_capture, debug_test_run, or debug_candidate_attach.').
				  (self
					   stringEnumSchemaPropertyNamed: 'operation'
					   description: 'Debug control operation to apply.'
					   values: MCPDebugControlRequest supportedOperations).
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description:
						   'Optional state token to reject stale debug control requests.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description:
						   'Optional state-scoped frame reference for step/restart operations. Defaults to the selected top frame.').
				  (self
					   booleanSchemaPropertyNamed: 'returnState'
					   description:
						   'Whether paused operations should include a post-action debug_state_get snapshot.'
					   default: true).
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
		  required: #( 'sessionId' 'operation' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugControl >> defaultName [

	^ 'debug_session_control_operation'
]

{ #category : 'defaults' }
MCPToolDebugControl >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description: 'Debug session identifier.').
				  (self
					   schemaPropertyNamed: 'operation'
					   type: 'string'
					   description: 'Control operation that was applied.').
				  (self
					   schemaPropertyNamed: 'previousStateId'
					   type: 'string'
					   description: 'Debug state token before control was applied.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description: 'Debug state token after control was applied.').
				  (self
					   schemaPropertyNamed: 'status'
					   type: 'string'
					   description: 'Debug session status after control.').
				  (self
					   schemaPropertyNamed: 'reason'
					   type: 'string'
					   description: 'Reason associated with the current status.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description:
					   'Post-action state-scoped frame reference when the operation used a frame.').
				  (self
					   schemaPropertyNamed: 'state'
					   type: 'object'
					   description:
					   'Post-action debug_state_get snapshot for paused operations when requested.').
				  (self
					   stringArraySchemaNamed: 'warnings'
					   description: 'Control-specific warnings.'
					   itemDescription: 'A warning message.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Control capability gates used for this response.') }
		  required:
			  #( 'sessionId' 'operation' 'previousStateId' 'stateId' 'status'
			     'reason' 'warnings' 'capabilities' )
]

{ #category : 'defaults' }
MCPToolDebugControl >> defaultTitle [

	^ 'Debug Control'
]

{ #category : 'private - request' }
MCPToolDebugControl >> parsedRequestFromToolRequest: request [

	^ MCPDebugControlRequest fromRequest: request tool: self
]
