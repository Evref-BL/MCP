Class {
	#name : 'MCPToolExecuteClassTest',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolExecuteClassTest >> executeWithArguments: arguments [

	| result |
	result := (self class environment at:
		           (arguments at: #className) asSymbol) run:
		          (arguments at: #testMethodName) asSymbol.

	^ { (MCPStructureTextContent text: result printString) }
]

{ #category : 'initialization' }
MCPToolExecuteClassTest >> initialize [

	super initialize.
	name := 'pharo-execute-all-class-test'.
	title := 'Execute Pharo a test of class'.
	description := 'Execute Pharo a test of class'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description:
						                'The name of the class that hold the test').
				               (MCPStructureProperties new
					                name: 'testMethodName';
					                type: 'string';
					                description: 'The name of the test method') };
		               yourself.
	icons := {  }
]
