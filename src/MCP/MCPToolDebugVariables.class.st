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

{ #category : 'metadata' }
MCPToolDebugVariables >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolDebugVariables >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self schemaPropertyNamed: 'variableRef' type: 'string' description: 'State-scoped variable/scope reference.').
				  (self schemaPropertyNamed: 'stateId' type: 'string' description: 'Optional stale-reference token.').
				  (self
					   variableDepthSchemaPropertyWithDescription: 'Expansion depth; 0 means metadata only.'
					   default: MCPDebugRequest defaultVariableDepth).
				  (self variableLimitSchemaPropertyWithDescription: 'Maximum child variables.' default: MCPDebugRequest defaultVariableLimit).
				  (self booleanSchemaPropertyNamed: 'includeIndexed' description: 'Include indexed children.' default: true).
				  (self booleanSchemaPropertyNamed: 'includeInstanceVariables' description: 'Include instance variables.' default: true) };
		  required: #( 'variableRef' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolDebugVariables >> commandForRequest: debugRequest [

	^ MCPDebugVariablesCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugVariables >> description [

	^ 'Expand one state-scoped variable or scope reference returned by debug_state_get.'
]

{ #category : 'private - request' }
MCPToolDebugVariables >> parsedRequestFromToolRequest: request [

	^ MCPDebugVariablesRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolDebugVariables >> title [

	^ 'Get Debug Variables'
]
