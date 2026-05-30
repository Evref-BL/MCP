"
MCP tool for evaluating expressions in a debugger frame.

The tool is intentionally scoped to a registered session and frame reference so evaluation happens in the live paused context.
"
Class {
	#name : 'MCPToolDebugEvaluate',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'icons' }
MCPToolDebugEvaluate class >> toolIconSpec [

	^ MCPToolIconSpec baseIconNamed: #bug badgeIconNamed: #go
]

{ #category : 'defaults' }
MCPToolDebugEvaluate class >> toolName [

	^ 'debug-evaluate'
]

{ #category : 'private - execution' }
MCPToolDebugEvaluate >> commandForRequest: debugRequest [

	^ MCPDebugEvaluateCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugEvaluate >> defaultDescription [

	^ 'Evaluate a Smalltalk expression in a selected DebugSession frame. The expression resolves frame receiver and temporaries and may mutate image state.'
]

{ #category : 'defaults' }
MCPToolDebugEvaluate >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #bug badgeIconNamed: #go) }
]

{ #category : 'defaults' }
MCPToolDebugEvaluate >> defaultInputSchema [

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
						   'Optional state token to reject stale frame references.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description:
						   'Optional state-scoped frame reference returned by debug-state. Defaults to the selected top frame.').
				  (self
					   schemaPropertyNamed: 'expression'
					   type: 'string'
					   description:
						   'Smalltalk expression to evaluate in the selected frame context.').
				  (self
					   integerSchemaPropertyNamed: 'resultPreviewCharacterLimit'
					   description:
						   'Maximum number of characters returned in resultPrintString.'
					   default: self resultPreviewCharacterLimit) };
		  required: #( 'sessionId' 'expression' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugEvaluate >> defaultName [

	^ 'debug-evaluate'
]

{ #category : 'defaults' }
MCPToolDebugEvaluate >> defaultOutputSchema [

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
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description: 'Frame reference used for evaluation.').
				  (self
					   schemaPropertyNamed: 'expression'
					   type: 'string'
					   description: 'Expression evaluated in the selected frame.').
				  (self
					   schemaPropertyNamed: 'resultClassName'
					   type: 'string'
					   description: 'The name of the evaluated result class.').
				  (self
					   schemaPropertyNamed: 'resultPrintString'
					   type: 'string'
					   description: 'Bounded printString of the evaluated result.').
				  (self
					   booleanSchemaPropertyNamed: 'hasResultVariableRef'
					   description:
					   'Whether resultVariableRef can be expanded with debug-variables.').
				  (self
					   schemaPropertyNamed: 'resultVariableRef'
					   type: 'string'
					   description:
					   'Optional state-scoped variable reference for the evaluation result.').
				  (self
					   schemaPropertyNamed: 'sideEffects'
					   type: 'string'
					   description: 'Side-effect expectation for this evaluation.').
				  (self
					   stringArraySchemaNamed: 'warnings'
					   description: 'Evaluation-specific warnings.'
					   itemDescription: 'A warning message.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Evaluation capability gates used for this response.') }
		  required:
			  #( 'sessionId' 'stateId' 'frameRef' 'expression' 'resultClassName'
			     'resultPrintString' 'hasResultVariableRef'
			     'sideEffects' 'warnings' 'capabilities' )
]

{ #category : 'defaults' }
MCPToolDebugEvaluate >> defaultTitle [

	^ 'Debug Evaluate'
]

{ #category : 'executing' }
MCPToolDebugEvaluate >> executeWithRequest: request [

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
	message := anError messageText
		           ifNil: [ anError asString ]
		           ifNotNil: [ :text | text asString ].
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

{ #category : 'testing' }
MCPToolDebugEvaluate >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]

{ #category : 'private' }
MCPToolDebugEvaluate >> syntaxFailureMessageFor: aNotice [

	| message |
	message := aNotice messageText
		           ifNil: [ aNotice asString ]
		           ifNotNil: [ :text | text asString ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Debug evaluation failed during compilation (';
				  nextPutAll: aNotice class name;
				  nextPutAll: '): ';
				  nextPutAll: message ]
]
