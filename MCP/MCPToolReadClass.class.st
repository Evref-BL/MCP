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
	^ self successResultText: 'Read class ' , className , '.' data: {
			  (#className -> className).
			  (#source -> content) } asDictionary
]

{ #category : 'initialization' }
MCPToolReadClass >> initialize [

	super initialize.
	name := 'pharo-read-class'.
	title := 'Read Pharo Class Definition'.
	description := 'Read the Tonel class definition for a class from the running Pharo image.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'className';
				                type: 'string';
				                description:
					                'The name of the class to read from the image.';
				                yourself) };
		               required: #( 'className' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description: 'The class that was read.').
				                (self
					                 schemaPropertyNamed: 'source'
					                 type: 'string'
					                 description:
					                 'The Tonel source exported for the class.') }
		                required: #( 'className' 'source' ).
	icons := {  }
]
