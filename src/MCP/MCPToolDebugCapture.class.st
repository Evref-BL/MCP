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

{ #category : 'metadata' }
MCPToolDebugCapture class >> toolName [

	^ 'debug_capture'
]

{ #category : 'private - execution' }
MCPToolDebugCapture >> commandForRequest: debugRequest [

	^ MCPDebugCaptureCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugCapture >> description [

	^ 'Evaluate Smalltalk in a bounded worker process and capture runtime exceptions as tracked debug sessions.'
]

{ #category : 'metadata' }
MCPToolDebugCapture >> inputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'expression'
					   type: 'string'
					   description: 'Smalltalk expression to evaluate.').
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description: 'Optional debug session name.').
				  (self
					   integerSchemaPropertyNamed: 'timeoutMilliseconds'
					   description: 'Maximum wait before timeout.'
					   default: MCPDebugCaptureRequest defaultTimeoutMilliseconds).
				  (self
					   integerSchemaPropertyNamed: 'resultPreviewCharacterLimit'
					   description: 'Maximum completed-result preview characters.'
					   default:
						   MCPDebugCaptureRequest defaultResultPreviewCharacterLimit).
				  (self
					   sourceContextLinesSchemaPropertyWithDescription:
						   'Source lines around selected frame.'
					   default: MCPDebugRequest defaultSourceContextLines).
				  (self
					   stackStartSchemaPropertyWithDescription:
						   'Zero-based stack offset.'
					   default: MCPDebugRequest defaultStackStart).
				  (self
					   stackLimitSchemaPropertyWithDescription:
						   'Maximum stack frames.'
					   default: MCPDebugRequest defaultStackLimit).
				  (self
					   variableDepthSchemaPropertyWithDescription:
						   'Inline variable preview depth.'
					   default: MCPDebugRequest defaultVariableDepth).
				  (self
					   variableLimitSchemaPropertyWithDescription:
						   'Maximum variables per scope.'
					   default: MCPDebugRequest defaultVariableLimit).
				  (self
					   booleanSchemaPropertyNamed: 'includeReceiver'
					   description: 'Include receiver scope.'
					   default: MCPDebugRequest defaultIncludeReceiver) };
		  required: #( 'expression' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolDebugCapture >> outputSchema [

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

{ #category : 'metadata' }
MCPToolDebugCapture >> title [

	^ 'Debug Capture'
]
