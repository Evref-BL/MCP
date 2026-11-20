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
	"A fixture is not a tool anyone asked for, and MCP's default group loads its own tests, so every fixture says so itself rather than relying on the package it sits in."

	^ false
]

{ #category : 'metadata' }
MCPHaltingTestTool class >> toolName [

	^ 'halting_test_tool'
]

{ #category : 'metadata' }
MCPHaltingTestTool >> buildInputSchema [

	^ MCPStructureInputSchema properties: #(  ) required: #(  )
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
