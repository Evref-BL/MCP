"
Test-only MCP tool that raises Halt so server-level tool-call error handling can be exercised without relying on MCPTool internals.
"
Class {
	#name : 'MCPHaltingTestTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPHaltingTestTool class >> isAbstract [

	^ true
]

{ #category : 'defaults' }
MCPHaltingTestTool class >> toolName [

	^ 'halting-test-tool'
]

{ #category : 'defaults' }
MCPHaltingTestTool >> defaultDescription [

	^ 'Raises Halt for MCP tool-call error handling tests.'
]

{ #category : 'defaults' }
MCPHaltingTestTool >> defaultInputSchema [

	^ MCPStructureInputSchema new
		type: 'object';
		properties: #(  );
		required: #(  );
		additionalProperties: false;
		yourself
]

{ #category : 'defaults' }
MCPHaltingTestTool >> defaultOutputSchema [

	^ self standardOutputSchemaForDataProperties: #(  ) required: #(  )
]

{ #category : 'defaults' }
MCPHaltingTestTool >> defaultTitle [

	^ 'Halting Test Tool'
]

{ #category : 'executing' }
MCPHaltingTestTool >> executeWithRequest: aRequest [

	(Smalltalk globals at: #Halt) signal: 'mcp tool halt test'
]
