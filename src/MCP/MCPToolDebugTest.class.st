"
MCP tool for stopping an SUnit test under debugger control.

It mirrors the Pharo browser's Debug tests and Debug test setup workflows, with an additional tearDown stop point for agent-driven inspection.
"
Class {
	#name : 'MCPToolDebugTest',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDebugTest class >> toolName [

	^ 'debug_test_run'
]

{ #category : 'metadata' }
MCPToolDebugTest >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'SUnit TestCase subclass.').
				  (self
					   schemaPropertyNamed: 'testMethodName'
					   type: 'string'
					   description: 'Test method selector.').
				  (self
					   stringEnumSchemaPropertyNamed: 'stopAt'
					   description: 'Test phase to stop at.'
					   values: MCPDebugTestRequest supportedStopPoints
					   default: 'test').
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description: 'Optional debug session name.').
				  (self
					   integerSchemaPropertyNamed: 'timeoutMilliseconds'
					   description: 'Maximum wait before timeout.'
					   default: MCPDebugTestRequest defaultTimeoutMilliseconds).
				  (self
					   integerSchemaPropertyNamed: 'resultPreviewCharacterLimit'
					   description: 'Maximum completed-result preview characters.'
					   default:
						   MCPDebugTestRequest defaultResultPreviewCharacterLimit).
				  (self
					   sourceContextLinesSchemaPropertyWithDescription:
						   'Source lines around selected frame.'
					   default: MCPDebugRequest defaultSourceContextLines).
				  (self
					   stackStartSchemaPropertyWithDescription:
						   'Zero-based stack offset.'
					   default: MCPDebugRequest defaultStackStart).
				  (self
					   stackLimitSchemaPropertyWithDescription:
						   'Maximum stack frames.'
					   default: MCPDebugRequest defaultStackLimit).
				  (self
					   variableDepthSchemaPropertyWithDescription:
						   'Inline preview depth.'
					   default: MCPDebugRequest defaultVariableDepth).
				  (self
					   variableLimitSchemaPropertyWithDescription:
						   'Maximum variables per scope.'
					   default: MCPDebugRequest defaultVariableLimit).
				  (self
					   booleanSchemaPropertyNamed: 'includeReceiver'
					   description: 'Include receiver scope.'
					   default: MCPDebugRequest defaultIncludeReceiver) };
		  required: #( 'className' 'testMethodName' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolDebugTest >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   booleanSchemaPropertyNamed: 'captured'
					   description:
					   'Whether test execution stopped in a debug session.').
				  (self
					   booleanSchemaPropertyNamed: 'timedOut'
					   description:
					   'Whether test execution timed out before completion or capture.').
				  (self
					   booleanSchemaPropertyNamed: 'passed'
					   description:
					   'Whether the test completed without stopping or failing.').
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'SUnit TestCase subclass name.').
				  (self
					   schemaPropertyNamed: 'testMethodName'
					   type: 'string'
					   description: 'Executed test method selector.').
				  (self
					   stringEnumSchemaPropertyNamed: 'stopAt'
					   description: 'Requested test execution phase.'
					   values: MCPDebugTestRequest supportedStopPoints).
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description:
					   'Captured debug session identifier, when captured.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description: 'Captured debug state token, when captured.').
				  (self
					   schemaPropertyNamed: 'session'
					   type: 'object'
					   description: 'Captured debug session summary.').
				  (self
					   schemaPropertyNamed: 'state'
					   type: 'object'
					   description:
					   'Immediate debug_state_get snapshot for captured execution.').
				  (self
					   integerSchemaPropertyNamed: 'timeoutMilliseconds'
					   description: 'Effective timeout used for this run.').
				  (self
					   stringArraySchemaNamed: 'warnings'
					   description: 'Debug-test-specific warnings.'
					   itemDescription: 'A warning message.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Debug-test capability gates used for this response.') }
		  required:
			  #( 'captured' 'timedOut' 'passed' 'className' 'testMethodName'
			     'stopAt' 'timeoutMilliseconds' 'warnings' 'capabilities' )
]

{ #category : 'private - execution' }
MCPToolDebugTest >> commandForRequest: debugRequest [

	^ MCPDebugTestCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugTest >> description [

	^ 'Run one SUnit test method under debugger control and stop at the requested phase.'
]

{ #category : 'private - request' }
MCPToolDebugTest >> parsedRequestFromToolRequest: request [

	^ MCPDebugTestRequest fromRequest: request tool: self
]

{ #category : 'testing' }
MCPToolDebugTest >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]

{ #category : 'metadata' }
MCPToolDebugTest >> title [

	^ 'Debug Test'
]
