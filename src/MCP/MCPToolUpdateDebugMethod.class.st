"
MCP tool for debugger-driven method updates.

It creates missing methods or recompiles the selected frame method, reports critiques, and proceeds the computation only when the update is accepted.
"
Class {
	#name : 'MCPToolUpdateDebugMethod',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateDebugMethod class >> toolName [

	^ 'debug_method_update'
]

{ #category : 'metadata' }
MCPToolUpdateDebugMethod >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description: 'Debug session id: debug_session_list, debug_capture, debug_test_run, debug_candidate_attach.').
				  (self schemaPropertyNamed: 'stateId' type: 'string' description: 'Optional stale-reference token.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description: 'Optional frame reference debug_state_get; default: selected top frame.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description: 'Optional replacement source. Default repair source handles DNU or subclass-responsibility.').
				  (self booleanSchemaPropertyNamed: 'ignoreCritiques' description: 'Proceed compile despite critiques.' default: false).
				  (self sourceContextLinesSchemaPropertyWithDescription: 'Source lines in returned state.' default: 5).
				  (self stackStartSchemaPropertyWithDescription: 'Zero-based stack frame offset returned in state.' default: 0).
				  (self stackLimitSchemaPropertyWithDescription: 'Maximum stack frames returned in state.' default: 20).
				  (self variableDepthSchemaPropertyWithDescription: 'Inline preview depth in returned state.' default: 1).
				  (self variableLimitSchemaPropertyWithDescription: 'Maximum variable previews returned in state.' default: 50).
				  (self booleanSchemaPropertyNamed: 'includeReceiver' description: 'Include receiver scope in returned state.' default: true) };
		  required: #( 'sessionId' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolUpdateDebugMethod >> commandForRequest: debugRequest [

	^ MCPUpdateDebugMethodCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolUpdateDebugMethod >> description [

	^ 'Update the method associated with a paused Pharo DebugSession frame. Supports normal debugger-time method updates and repair flows for resumable exceptions, gates on critiques unless ignoreCritiques=true, then proceeds the computation when possible.'
]

{ #category : 'private - request' }
MCPToolUpdateDebugMethod >> parsedRequestFromToolRequest: request [

	^ MCPUpdateDebugMethodRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolUpdateDebugMethod >> title [

	^ 'Update Debug Method'
]

{ #category : 'private - data' }
MCPToolUpdateDebugMethod >> updateWarnings [

	^ #( 'debug_method_update compiles Smalltalk code in the running image and may mutate or resume a suspended debug process.' )
]
