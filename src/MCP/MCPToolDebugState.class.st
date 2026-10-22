"
MCP tool for retrieving a composite debug_state_get snapshot.

It is the primary read tool for debugger sessions, returning stack, selected source context, shallow scopes, exception metadata, and repair actions.
"
Class {
	#name : 'MCPToolDebugState',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDebugState class >> toolName [

	^ 'debug_state_get'
]

{ #category : 'metadata' }
MCPToolDebugState >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolDebugState >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self schemaPropertyNamed: 'sessionId' type: 'string' description: 'Debug session identifier.').
				  (self schemaPropertyNamed: 'stateId' type: 'string' description: 'Optional stale-reference token.').
				  (self schemaPropertyNamed: 'frameRef' type: 'string' description: 'Optional state-scoped frame reference.').
				  (self
					   sourceContextLinesSchemaPropertyWithDescription: 'Source lines around selected frame.'
					   default: MCPDebugRequest defaultSourceContextLines).
				  (self stackStartSchemaPropertyWithDescription: 'Zero-based stack offset.' default: MCPDebugRequest defaultStackStart).
				  (self stackLimitSchemaPropertyWithDescription: 'Maximum stack frames.' default: MCPDebugRequest defaultStackLimit).
				  (self variableDepthSchemaPropertyWithDescription: 'Inline preview depth.' default: MCPDebugRequest defaultVariableDepth).
				  (self
					   variableLimitSchemaPropertyWithDescription: 'Maximum variables per scope.'
					   default: MCPDebugRequest defaultVariableLimit).
				  (self
					   booleanSchemaPropertyNamed: 'includeReceiver'
					   description: 'Include receiver scope.'
					   default: MCPDebugRequest defaultIncludeReceiver) };
		  required: #( 'sessionId' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolDebugState >> commandForRequest: debugRequest [

	^ MCPDebugStateCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugState >> description [

	^ 'Return a compact snapshot of one tracked Pharo debug session: selected frame, source, stack, shallow scopes, and repair actions.'
]

{ #category : 'private - request' }
MCPToolDebugState >> parsedRequestFromToolRequest: request [

	^ MCPDebugStateRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolDebugState >> title [

	^ 'Get Debug State'
]
