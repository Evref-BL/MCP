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

{ #category : 'metadata' }
MCPHaltingTestTool class >> toolName [

	^ 'halting-test-tool'
]

{ #category : 'metadata' }
MCPHaltingTestTool >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: #(  );
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPHaltingTestTool >> buildOutputSchema [

	^ self standardOutputSchemaForDataProperties: #(  ) required: #(  )
]

{ #category : 'metadata' }
MCPHaltingTestTool >> description [

	^ 'Raises Halt for MCP tool-call error handling tests.'
]

{ #category : 'executing' }
MCPHaltingTestTool >> executeWithRequest: aRequest [

	(Smalltalk globals at: #Halt) signal: 'mcp tool halt test'
]

{ #category : 'metadata' }
MCPHaltingTestTool >> groupName [

	^ 'plugins'
]

{ #category : 'metadata' }
MCPHaltingTestTool >> title [

	^ 'Halting Test Tool'
]
