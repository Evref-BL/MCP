Class {
	#name : 'MCPToolEval',
	#superclass : 'MCPTool',
	#category : 'MCP',
	#package : 'MCP'
}

{ #category : 'executing' }
MCPToolEval >> executeWithArguments: arguments [

	| compiler answer |
	compiler := SmalltalkImage current compiler.
	compiler compilationContext isScripting: true.
	compiler failBlock: [ nil ].
	answer := compiler evaluate: (arguments at: #code).

	^ { (MCPStructureTextContent text: answer printString) }
]

{ #category : 'initialization' }
MCPToolEval >> initialize [

	super initialize.
	name := 'pharo-eval'.
	title := 'Execute Pharo Code'.
	description := 'Executes Smalltalk code in the Pharo image and returns the result (may have side effects).'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'code';
				                type: 'string';
				                description:
					                'The name of the package we will look class into') };
		               yourself.
	icons := {  }
]
