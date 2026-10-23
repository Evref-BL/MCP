"
MCP tool for evaluating expressions in a debugger frame.

The tool is intentionally scoped to a registered session and frame reference so evaluation happens in the live paused context.
"
Class {
	#name : 'MCPToolDebugEvaluate',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDebugEvaluate class >> toolName [

	^ 'debug_expression_evaluate'
]

{ #category : 'metadata' }
MCPToolDebugEvaluate >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description:
						   'Opaque debug session identifier returned by debug_session_list or debug_candidate_attach.').
				  (self schemaPropertyNamed: 'stateId' type: 'string' description: 'Optional state token to reject stale frame references.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description: 'Optional state-scoped frame reference returned by debug_state_get. Defaults to the selected top frame.').
				  (self
					   schemaPropertyNamed: 'expression'
					   type: 'string'
					   description: 'Smalltalk expression to evaluate in the selected frame context.').
				  (self
					   integerSchemaPropertyNamed: 'resultPreviewCharacterLimit'
					   description: 'Maximum number of characters returned in resultPrintString.'
					   default: self resultPreviewCharacterLimit) };
		  required: #( 'sessionId' 'expression' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolDebugEvaluate >> commandForRequest: debugRequest [

	^ MCPDebugEvaluateCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugEvaluate >> description [

	^ 'Evaluate a Smalltalk expression in a selected DebugSession frame. The expression resolves frame receiver and temporaries and may mutate image state.'
]

{ #category : 'private - request' }
MCPToolDebugEvaluate >> parsedRequestFromToolRequest: request [

	^ MCPDebugEvaluateRequest fromRequest: request tool: self
]

{ #category : 'private' }
MCPToolDebugEvaluate >> resultPreviewCharacterLimit [

	^ 10000
]

{ #category : 'private' }
MCPToolDebugEvaluate >> runtimeFailureMessageFor: anError [

	| message |
	message := anError messageText ifNil: [ anError asString ] ifNotNil: [ :text | text asString ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Debug evaluation failed during execution (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: message.
			  anError signalerContext ifNotNil: [ :context |
					  stream
						  nextPutAll: ' Signaler context: ';
						  nextPutAll: context printString ] ]
]

{ #category : 'private' }
MCPToolDebugEvaluate >> syntaxFailureMessageFor: aNotice [

	| message |
	message := aNotice messageText ifNil: [ aNotice asString ] ifNotNil: [ :text | text asString ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Debug evaluation failed during compilation (';
				  nextPutAll: aNotice class name;
				  nextPutAll: '): ';
				  nextPutAll: message ]
]

{ #category : 'metadata' }
MCPToolDebugEvaluate >> title [

	^ 'Debug Evaluate'
]
