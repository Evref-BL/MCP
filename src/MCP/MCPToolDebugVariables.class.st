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

{ #category : 'metadata' }
MCPToolDebugVariables class >> toolName [

	^ 'debug_variable_get'
]

{ #category : 'private - execution' }
MCPToolDebugVariables >> commandForRequest: debugRequest [

	^ MCPDebugVariablesCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugVariables >> description [

	^ 'Expand one state-scoped variable or scope reference returned by debug_state_get.'
]

{ #category : 'metadata' }
MCPToolDebugVariables >> inputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'variableRef'
					   type: 'string'
					   description: 'State-scoped variable/scope reference.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description: 'Optional stale-reference token.').
				  (self
					   variableDepthSchemaPropertyWithDescription:
						   'Expansion depth; 0 means metadata only.'
					   default: MCPDebugRequest defaultVariableDepth).
				  (self
					   variableLimitSchemaPropertyWithDescription:
						   'Maximum child variables.'
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

{ #category : 'metadata' }
MCPToolDebugVariables >> outputSchema [

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

{ #category : 'private - request' }
MCPToolDebugVariables >> parsedRequestFromToolRequest: request [

	^ MCPDebugVariablesRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolDebugVariables >> title [

	^ 'Get Debug Variables'
]
