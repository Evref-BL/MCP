"
MCP tool for expanding debugger variables.

It lets callers drill into state-scoped scope or variable references without refreshing the whole debug-state snapshot.
"
Class {
	#name : 'MCPToolDebugVariables',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'icons' }
MCPToolDebugVariables class >> toolIconSpec [

	^ MCPToolIconSpec baseIconNamed: #open badgeIconNamed: #inspect
]

{ #category : 'defaults' }
MCPToolDebugVariables class >> toolName [

	^ 'debug-variables'
]

{ #category : 'private - execution' }
MCPToolDebugVariables >> commandForRequest: debugRequest [

	^ MCPDebugVariablesCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultDescription [

	^ 'Expand a state-scoped debug variable or scope reference returned by debug-state. Supports receiver, temporaries, instance-variable children, and indexed children with bounded previews.'
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #open badgeIconNamed: #inspect) }
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'variableRef'
					   type: 'string'
					   description:
						   'Opaque state-scoped scope or variable reference returned by debug-state or debug-variables.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description:
						   'Optional state token; when supplied it must match the token embedded in variableRef.').
				  (self
					   integerSchemaPropertyNamed: 'variableDepth'
					   description:
						   'Requested expansion depth. Use 0 to describe the variable without returning children.'
					   default: 1).
				  (self
					   integerSchemaPropertyNamed: 'variableLimit'
					   description: 'Maximum number of child variables to return.'
					   default: 50).
				  (self
					   booleanSchemaPropertyNamed: 'includeIndexed'
					   description:
						   'Whether to include indexed child slots when the object supports at:.'
					   default: true).
				  (self
					   booleanSchemaPropertyNamed: 'includeInstanceVariables'
					   description: 'Whether to include named instance variables.'
					   default: true) };
		  required: #( 'variableRef' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultName [

	^ 'debug-variables'
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultOutputSchema [

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
					   schemaPropertyNamed: 'variableRef'
					   type: 'string'
					   description: 'Expanded variable or scope reference.').
				  (self
					   schemaPropertyNamed: 'kind'
					   type: 'string'
					   description: 'Expanded reference kind, scope or variable.').
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description: 'Scope or variable name.').
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description:
					   'Class name of the expanded value when available.').
				  (self
					   schemaPropertyNamed: 'printString'
					   type: 'string'
					   description:
					   'Bounded printString of the expanded value when available.').
				  (self
					   booleanSchemaPropertyNamed: 'hasChildren'
					   description: 'Whether more child variables are available.').
				  (self
					   schemaPropertyNamed: 'variables'
					   type: 'array'
					   description: 'Expanded child variables.').
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description: 'Number of child variables returned.').
				  (self
					   booleanSchemaPropertyNamed: 'truncated'
					   description:
					   'Whether the response was truncated by variableLimit.').
				  (self
					   stringArraySchemaNamed: 'warnings'
					   description: 'Expansion-specific warnings.'
					   itemDescription: 'A warning message.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Variable expansion capability gates used for this response.') }
		  required:
			  #( 'sessionId' 'stateId' 'variableRef' 'kind' 'variables'
			     'totalCount' 'truncated' 'warnings' 'capabilities' )
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultTitle [

	^ 'Debug Variables'
]

{ #category : 'executing' }
MCPToolDebugVariables >> executeWithRequest: request [

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
MCPToolDebugVariables >> parsedRequestFromToolRequest: request [

	^ MCPDebugVariablesRequest fromRequest: request tool: self
]
