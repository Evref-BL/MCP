Class {
	#name : 'MCPToolReadClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolReadClass >> executeWithArguments: arguments [

	| className content |
	className := arguments at: #className.
	content := String streamContents: [ :stream |
		           TonelWriter
			           exportClass:
			           (self class environment at: className asSymbol)
			           on: stream ].

	^ { (MCPStructureTextContent text: content) }
]

{ #category : 'initialization' }
MCPToolReadClass >> initialize [

	super initialize.
	name := 'pharo-read-class'.
	title := 'Read Pharo Class'.
	description := 'Reads the Tonel source of a class from the Pharo image (no side effects).'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'className';
				                type: 'string';
				                description:
					                'The name of the class to read from the image.') };
		               required: #( 'className' );
		               yourself.
	icons := {  }
]
