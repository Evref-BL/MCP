"
Test-only MCP tool that raises Halt so server-level tool-call error handling can be exercised without relying on MCPTool internals.
"
Class {
	#name : 'MCPHaltingTestTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPHaltingTestTool class >> shouldAutoRegister [
	"A fixture is not a tool anyone asked for, and MCP's default group loads its own tests. It used to call itself abstract to stay out of the catalog, which was a lie: the tests instantiate it."

	^ false
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

{ #category : 'testing' }
MCPHaltingTestTool >> shouldRecordObservability [

	^ false
]

{ #category : 'metadata' }
MCPHaltingTestTool >> title [

	^ 'Halting Test Tool'
]
