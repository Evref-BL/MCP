Class {
	#name : 'MCPToolExecuteAllTestOfClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolExecuteAllTestOfClass >> executeWithArguments: arguments [

	| result |
	result := (self class environment at:
		           (arguments at: #className) asSymbol) suite run.

	^ { (MCPStructureTextContent text: result printString) }
]

{ #category : 'initialization' }
MCPToolExecuteAllTestOfClass >> initialize [

	super initialize.
	name := 'pharo-execute-class-test'.
	title := 'Execute Pharo all tests of class'.
	description := 'Execute Pharo all tests of class'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'className';
				                type: 'string';
				                description:
					                'The name of the class that hold the test') };
		               yourself.
	icons := {  }
]
