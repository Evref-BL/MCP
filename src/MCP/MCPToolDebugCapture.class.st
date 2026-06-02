"
MCP tool for capturing runtime exceptions from evaluated code.

It runs code in a bounded worker process and registers a debugger session when execution raises a runtime exception.
"
Class {
	#name : 'MCPToolDebugCapture',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolDebugCapture class >> toolName [

	^ 'debug_capture'
]

{ #category : 'private - execution' }
MCPToolDebugCapture >> commandForRequest: debugRequest [

	^ MCPDebugCaptureCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugCapture >> defaultDescription [

	^ 'Evaluate Smalltalk in a bounded worker process and capture runtime exceptions as tracked Pharo DebugSession records with an immediate debug_state_get snapshot.'
]

{ #category : 'defaults' }
MCPToolDebugCapture >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #bug badgeIconNamed: #rightSide) }
]

{ #category : 'defaults' }
MCPToolDebugCapture >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'expression'
					   type: 'string'
					   description:
						   'Smalltalk expression to evaluate in a forked worker process.').
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description:
						   'Optional human-readable name for a captured debug session.').
				  (self
					   integerSchemaPropertyNamed: 'timeoutMilliseconds'
					   description:
						   'Maximum time to wait for completion or capture. Values above the implementation cap are reduced.'
					   default: MCPDebugCaptureRequest defaultTimeoutMilliseconds).
				  (self
					   integerSchemaPropertyNamed: 'resultPreviewCharacterLimit'
					   description:
						   'Maximum number of characters returned in resultPrintString.'
					   default:
						   MCPDebugCaptureRequest defaultResultPreviewCharacterLimit).
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
		  required: #( 'expression' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugCapture >> defaultName [

	^ 'debug_capture'
]

{ #category : 'defaults' }
MCPToolDebugCapture >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   booleanSchemaPropertyNamed: 'captured'
					   description:
					   'Whether execution stopped on a captured runtime exception.').
				  (self
					   booleanSchemaPropertyNamed: 'timedOut'
					   description:
					   'Whether capture timed out before completion or exception capture.').
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description:
					   'Captured debug session identifier, when captured.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description: 'Captured debug state token, when captured.').
				  (self
					   schemaPropertyNamed: 'session'
					   type: 'object'
					   description: 'Captured debug session summary.').
				  (self
					   schemaPropertyNamed: 'state'
					   type: 'object'
					   description:
					   'Immediate debug_state_get snapshot for captured exceptions.').
				  (self
					   schemaPropertyNamed: 'resultClassName'
					   type: 'string'
					   description:
					   'Result class name when execution completed normally.').
				  (self
					   schemaPropertyNamed: 'resultPrintString'
					   type: 'string'
					   description:
					   'Bounded result printString when execution completed normally.').
				  (self
					   integerSchemaPropertyNamed: 'timeoutMilliseconds'
					   description: 'Effective timeout used for this capture.').
				  (self
					   stringArraySchemaNamed: 'warnings'
					   description: 'Capture-specific warnings.'
					   itemDescription: 'A warning message.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Capture capability gates used for this response.') }
		  required:
		  #( 'captured' 'timedOut' 'timeoutMilliseconds'
		     'warnings' 'capabilities' )
]

{ #category : 'defaults' }
MCPToolDebugCapture >> defaultTitle [

	^ 'Debug Capture'
]

{ #category : 'private - request' }
MCPToolDebugCapture >> parsedRequestFromToolRequest: request [

	^ MCPDebugCaptureRequest fromRequest: request tool: self
]

{ #category : 'testing' }
MCPToolDebugCapture >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]

{ #category : 'private' }
MCPToolDebugCapture >> syntaxFailureMessageFor: aNotice [

	| message |
	message := aNotice messageText
		           ifNil: [ aNotice asString ]
		           ifNotNil: [ :text | text asString ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Debug capture failed during compilation (';
				  nextPutAll: aNotice class name;
				  nextPutAll: '): ';
				  nextPutAll: message ]
]
