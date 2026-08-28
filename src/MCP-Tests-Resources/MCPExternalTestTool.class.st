"
Concrete MCPTool subclass in a non-MCP package used to verify MCP contract tests do not reject downstream extension tools.
"
Class {
	#name : 'MCPExternalTestTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tests-Resources-Tools',
	#package : 'MCP-Tests-Resources',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPExternalTestTool class >> groupName [

	^ 'external-tests'
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
MCPExternalTestTool >> buildOutputSchema [

	^ self standardOutputSchemaForDataProperties: #(  ) required: #(  )
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
