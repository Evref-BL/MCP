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

{ #category : 'defaults' }
MCPToolDebugTest class >> toolName [

	^ 'debug_test_run'
]

{ #category : 'private - execution' }
MCPToolDebugTest >> commandForRequest: debugRequest [

	^ MCPDebugTestCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugTest >> defaultDescription [

	^ 'Run one SUnit test method under debugger control and stop at the requested test phase with an immediate debug_state_get snapshot.'
]

{ #category : 'defaults' }
MCPToolDebugTest >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'SUnit TestCase subclass name.').
				  (self
					   schemaPropertyNamed: 'testMethodName'
					   type: 'string'
					   description: 'Test method selector to debug.').
				  (self
					   stringEnumSchemaPropertyNamed: 'stopAt'
					   description:
						   'Test execution phase where debugger control should stop.'
					   values: MCPDebugTestRequest supportedStopPoints
					   default: 'test').
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description:
						   'Optional human-readable name for a captured debug session.').
				  (self
					   integerSchemaPropertyNamed: 'timeoutMilliseconds'
					   description:
						   'Maximum time to wait for completion or capture. Values above the implementation cap are reduced.'
					   default: MCPDebugTestRequest defaultTimeoutMilliseconds).
				  (self
					   integerSchemaPropertyNamed: 'resultPreviewCharacterLimit'
					   description:
						   'Maximum number of characters returned in resultPrintString.'
					   default:
						   MCPDebugTestRequest defaultResultPreviewCharacterLimit).
				  (self
					   integerSchemaPropertyNamed: 'sourceContextLines'
					   description:
						   'Number of source context lines requested in returned state.'
					   default: 5).
				  (self
					   integerSchemaPropertyNamed: 'stackStart'
					   description:
						   'Zero-based stack frame offset for returned state.'
					   default: 0).
				  (self
					   integerSchemaPropertyNamed: 'stackLimit'
					   description:
						   'Maximum number of stack frames in returned state.'
					   default: 20).
				  (self
					   integerSchemaPropertyNamed: 'variableDepth'
					   description:
						   'Inline variable preview depth in returned state.'
					   default: 1).
				  (self
					   integerSchemaPropertyNamed: 'variableLimit'
					   description:
						   'Maximum number of variables to preview in returned state.'
					   default: 50).
				  (self
					   booleanSchemaPropertyNamed: 'includeReceiver'
					   description:
						   'Whether returned state should include the receiver scope.'
					   default: true) };
		  required: #( 'className' 'testMethodName' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugTest >> defaultName [

	^ 'debug_test_run'
]

{ #category : 'defaults' }
MCPToolDebugTest >> defaultOutputSchema [

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

{ #category : 'defaults' }
MCPToolDebugTest >> defaultTitle [

	^ 'Debug Test'
]

{ #category : 'private - request' }
MCPToolDebugTest >> parsedRequestFromToolRequest: request [

	^ MCPDebugTestRequest fromRequest: request tool: self
]

{ #category : 'testing' }
MCPToolDebugTest >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]
