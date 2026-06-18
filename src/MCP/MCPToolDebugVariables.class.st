"
MCP tool for expanding debugger variables.

It lets callers drill into state-scoped scope or variable references without refreshing the whole debug_state_get snapshot.
"
Class {
	#name : 'MCPToolDebugVariables',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolDebugVariables class >> toolName [

	^ 'debug_variable_get'
]

{ #category : 'private - execution' }
MCPToolDebugVariables >> commandForRequest: debugRequest [

	^ MCPDebugVariablesCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultDescription [

	^ 'Expand one state-scoped variable or scope reference returned by debug_state_get.'
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultIcons [

	^ { (self
		   pngCompositeBaseIconNamed: #bug
		   badgeIconNamed: #instVarsSelected) }
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'variableRef'
					   type: 'string'
					   description: 'State-scoped variable or scope reference.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description:
						   'Optional state token for stale-reference checks.').
				  (self
					   integerSchemaPropertyNamed: 'variableDepth'
					   description: 'Expansion depth; use 0 for metadata only.'
					   default: MCPDebugRequest defaultVariableDepth).
				  (self
					   integerSchemaPropertyNamed: 'variableLimit'
					   description: 'Maximum child variables.'
					   default: MCPDebugRequest defaultVariableLimit).
				  (self
					   booleanSchemaPropertyNamed: 'includeIndexed'
					   description: 'Include indexed children.'
					   default: true).
				  (self
					   booleanSchemaPropertyNamed: 'includeInstanceVariables'
					   description: 'Include instance variables.'
					   default: true) };
		  required: #( 'variableRef' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugVariables >> defaultName [

	^ 'debug_variable_get'
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

	^ 'Get Debug Variables'
]

{ #category : 'private - request' }
MCPToolDebugVariables >> parsedRequestFromToolRequest: request [

	^ MCPDebugVariablesRequest fromRequest: request tool: self
]
