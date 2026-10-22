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

{ #category : 'metadata' }
MCPToolDebugCapture >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self schemaPropertyNamed: 'expression' type: 'string' description: 'Smalltalk expression to evaluate.').
				  (self schemaPropertyNamed: 'name' type: 'string' description: 'Optional debug session name.').
				  (self
					   integerSchemaPropertyNamed: 'timeoutMilliseconds'
					   description: 'Maximum wait before timeout.'
					   default: MCPDebugCaptureRequest defaultTimeoutMilliseconds).
				  (self
					   integerSchemaPropertyNamed: 'resultPreviewCharacterLimit'
					   description: 'Maximum completed-result preview characters.'
					   default: MCPDebugCaptureRequest defaultResultPreviewCharacterLimit).
				  (self
					   sourceContextLinesSchemaPropertyWithDescription: 'Source lines around selected frame.'
					   default: MCPDebugRequest defaultSourceContextLines).
				  (self stackStartSchemaPropertyWithDescription: 'Zero-based stack offset.' default: MCPDebugRequest defaultStackStart).
				  (self stackLimitSchemaPropertyWithDescription: 'Maximum stack frames.' default: MCPDebugRequest defaultStackLimit).
				  (self
					   variableDepthSchemaPropertyWithDescription: 'Inline variable preview depth.'
					   default: MCPDebugRequest defaultVariableDepth).
				  (self
					   variableLimitSchemaPropertyWithDescription: 'Maximum variables per scope.'
					   default: MCPDebugRequest defaultVariableLimit).
				  (self
					   booleanSchemaPropertyNamed: 'includeReceiver'
					   description: 'Include receiver scope.'
					   default: MCPDebugRequest defaultIncludeReceiver) };
		  required: #( 'expression' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolDebugCapture >> commandForRequest: debugRequest [

	^ MCPDebugCaptureCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugCapture >> description [

	^ 'Evaluate Smalltalk in a bounded worker process and capture runtime exceptions as tracked debug sessions.'
]

{ #category : 'private - request' }
MCPToolDebugCapture >> parsedRequestFromToolRequest: request [

	^ MCPDebugCaptureRequest fromRequest: request tool: self
]

{ #category : 'private' }
MCPToolDebugCapture >> syntaxFailureMessageFor: aNotice [

	| message |
	message := aNotice messageText ifNil: [ aNotice asString ] ifNotNil: [ :text | text asString ].
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
