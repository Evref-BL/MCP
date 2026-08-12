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

{ #category : 'metadata' }
MCPToolDebugState >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self schemaPropertyNamed: 'sessionId' type: 'string' description: 'Debug session identifier.').
				  (self schemaPropertyNamed: 'stateId' type: 'string' description: 'Current debug state token.').
				  (self schemaPropertyNamed: 'status' type: 'string' description: 'Current debug session status.').
				  (self schemaPropertyNamed: 'reason' type: 'string' description: 'Reason the debug session is stopped or tracked.').
				  (self
					   schemaPropertyNamed: 'exception'
					   type: 'object'
					   description: 'Exception associated with the debug session when available.').
				  (self schemaPropertyNamed: 'location' type: 'object' description: 'Selected execution location.').
				  (self schemaPropertyNamed: 'source' type: 'object' description: 'Source context for the selected frame.').
				  (self schemaPropertyNamed: 'selectedFrame' type: 'object' description: 'Selected stack frame.').
				  (self schemaPropertyNamed: 'scopes' type: 'array' description: 'State-scoped variable scopes for the selected frame.').
				  (self schemaPropertyNamed: 'callStack' type: 'array' description: 'Visible call stack frames.').
				  (self
					   schemaPropertyNamed: 'repairActions'
					   type: 'array'
					   description:
					   'Repair actions available for debugger-driven development, such as debug_method_update arguments for a missing or stub method.').
				  (self integerSchemaPropertyNamed: 'stackStart' description: 'Zero-based stack offset used for the response.').
				  (self integerSchemaPropertyNamed: 'stackLimit' description: 'Stack frame limit used for the response.').
				  (self integerSchemaPropertyNamed: 'totalFrames' description: 'Number of stack frames known to this snapshot.').
				  (self schemaPropertyNamed: 'capabilities' type: 'object' description: 'Debugger feature gates available for this session.').
				  (self stringArraySchemaNamed: 'warnings' description: 'Snapshot-specific warnings.' itemDescription: 'A warning message.') }
		  required: #( 'sessionId' 'stateId' 'status' 'callStack' 'repairActions' 'capabilities' 'warnings' )
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
