"
Abstract base for MCP debugger tools.

It centralizes the parse/execute/result wrapper shared by debugger tools while subclasses provide request parsing, command creation, schemas, and public metadata.
"
Class {
	#name : 'MCPToolDebug',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebug class >> isAbstract [

	^ self = MCPToolDebug
]

{ #category : 'private - schema' }
MCPToolDebug >> boundedIntegerSchemaPropertyNamed: propertyName description: propertyDescription default: defaultValue maximum: maximumValue [

	| property |
	property := self
		            nonNegativeIntegerSchemaPropertyNamed: propertyName
		            description: propertyDescription
		            default: defaultValue.
	property maximum: maximumValue.
	^ property
]

{ #category : 'metadata' }
MCPToolDebug >> buildInputSchema [

	^ MCPStructureInputSchema new
		type: 'object';
		properties: self inputProperties;
		required: self requiredInputProperties;
		additionalProperties: false;
		yourself
]

{ #category : 'private - execution' }
MCPToolDebug >> commandForRequest: debugRequest [

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolDebug >> debugErrorDetailsFor: anError [

	^ anError
		  mcpCommandErrorDo: [ :commandError |
		  commandError structuredDetails ]
		  otherwise: [ self errorDetailsFor: anError ]
]

{ #category : 'private - errors' }
MCPToolDebug >> errorResultForDebugError: anError [

	^ self
		  errorResultText: (anError messageText
				   ifNil: [ anError asString ]
				   ifNotNil: [ :text | text asString ])
		  details: (self debugErrorDetailsFor: anError)
]

{ #category : 'executing' }
MCPToolDebug >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :debugRequest |
				  self resultForCommandResult:
					  (self commandForRequest: debugRequest) execute ]
		  onError: [ :error :ignored | self errorResultForDebugError: error ]
]

{ #category : 'private - schema' }
MCPToolDebug >> inputProperties [

	^ #( )
]

{ #category : 'private - schema' }
MCPToolDebug >> nonNegativeIntegerSchemaPropertyNamed: propertyName description: propertyDescription default: defaultValue [

	| property |
	property := self
		            integerSchemaPropertyNamed: propertyName
		            description: propertyDescription
		            default: defaultValue.
	property minimum: 0.
	^ property
]

{ #category : 'private - schema' }
MCPToolDebug >> requiredInputProperties [

	^ #( )
]

{ #category : 'private - execution' }
MCPToolDebug >> resultForCommandResult: commandResult [

	commandResult isError ifTrue: [
			^ self
				  errorResultText: commandResult summary
				  details: commandResult errorDetails ].
	^ self
		  successResultText: commandResult summary
		  data: commandResult data
		  warnings: commandResult warnings
]

{ #category : 'private - schema' }
MCPToolDebug >> sessionIdSchemaProperty [

	^ self
		schemaPropertyNamed: 'sessionId'
		type: 'string'
		description:
		'Opaque debug session identifier returned by debug_session_list, debug_capture, debug_test_run, or debug_candidate_attach.'
]

{ #category : 'private - schema' }
MCPToolDebug >> sourceContextLinesSchemaPropertyWithDescription: aDescription default: defaultValue [

	^ self
		  boundedIntegerSchemaPropertyNamed: 'sourceContextLines'
		  description: aDescription
		  default: defaultValue
		  maximum: MCPDebugRequest maximumSourceContextLines
]

{ #category : 'private - schema' }
MCPToolDebug >> stackLimitSchemaPropertyWithDescription: aDescription default: defaultValue [

	^ self
		  boundedIntegerSchemaPropertyNamed: 'stackLimit'
		  description: aDescription
		  default: defaultValue
		  maximum: MCPDebugRequest maximumStackLimit
]

{ #category : 'private - schema' }
MCPToolDebug >> stackStartSchemaPropertyWithDescription: aDescription default: defaultValue [

	^ self
		  nonNegativeIntegerSchemaPropertyNamed: 'stackStart'
		  description: aDescription
		  default: defaultValue
]

{ #category : 'private - schema' }
MCPToolDebug >> variableDepthSchemaPropertyWithDescription: aDescription default: defaultValue [

	^ self
		  boundedIntegerSchemaPropertyNamed: 'variableDepth'
		  description: aDescription
		  default: defaultValue
		  maximum: MCPDebugRequest maximumVariableDepth
]

{ #category : 'private - schema' }
MCPToolDebug >> variableLimitSchemaPropertyWithDescription: aDescription default: defaultValue [

	^ self
		  boundedIntegerSchemaPropertyNamed: 'variableLimit'
		  description: aDescription
		  default: defaultValue
		  maximum: MCPDebugRequest maximumVariableLimit
]
