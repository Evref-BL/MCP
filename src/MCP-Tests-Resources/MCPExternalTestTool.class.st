"
Concrete MCPTool subclass in a non-MCP package used to verify MCP contract tests do not reject downstream extension tools.
"
Class {
	#name : 'MCPExternalTestTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'metadata' }
MCPExternalTestTool class >> groupName [

	^ 'external-tests'
]

{ #category : 'testing' }
MCPExternalTestTool class >> shouldAutoRegister [
	"A fixture is not a tool anyone asked for, and MCP's default group loads its own tests, so every fixture says so itself rather than relying on the package it sits in."

	^ false
]

{ #category : 'metadata' }
MCPExternalTestTool class >> toolName [

	^ 'external_test_tool'
]

{ #category : 'metadata' }
MCPExternalTestTool >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: #(  );
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPExternalTestTool >> description [

	^ 'Test fixture for external MCP tool extensions.'
]

{ #category : 'executing' }
MCPExternalTestTool >> executeWithRequest: aRequest [

	^ self successResultText: 'External test tool executed.' data: Dictionary new
]

{ #category : 'testing' }
MCPExternalTestTool >> shouldRecordObservability [

	^ false
]

{ #category : 'metadata' }
MCPExternalTestTool >> title [

	^ 'External Test Tool'
]
