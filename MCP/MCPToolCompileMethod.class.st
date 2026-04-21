Class {
	#name : 'MCPToolCompileMethod',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolCompileMethod >> behaviorFromArguments: arguments [

	| targetClass |
	targetClass := self class environment at:
		               (arguments at: #className) asSymbol.
	^ (arguments at: #classSide)
		  ifTrue: [ targetClass classSide ]
		  ifFalse: [ targetClass ]
]

{ #category : 'executing' }
MCPToolCompileMethod >> executeWithArguments: arguments [

	| behavior methodSource protocol selector compiledMethod |
	behavior := self behaviorFromArguments: arguments.
	methodSource := self normalizedMethodSourceFrom:
		                (arguments at: #methodSource).
	protocol := arguments at: #protocol.
	selector := behavior compile: methodSource classified: protocol.
	compiledMethod := behavior >> selector.
	compiledMethod reformat.
	^ { (MCPStructureTextContent text:
		   'Compiled '
		   , (self methodReferenceFor: behavior selector: selector)
		   , ' in protocol ' , protocol printString , '.') }
]

{ #category : 'initialization' }
MCPToolCompileMethod >> initialize [

	super initialize.
	name := 'pharo-compile-method'.
	title := 'Compile Pharo Method'.
	description := 'Compiles a method on the instance side or class side of a Pharo class, normalizes line endings to CR, and reformats the compiled method.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description:
						                'The name of the class that will receive the method.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'classSide';
					                type: 'boolean';
					                description:
						                'Whether to compile on the class side (true) or instance side (false).';
					                yourself).
				               (MCPStructureProperties new
					                name: 'methodSource';
					                type: 'string';
					                description: 'The full method source to compile.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'protocol';
					                type: 'string';
					                description:
						                'The method protocol to install the method into, including extension protocols.';
					                yourself) };
		               required:
		               #( 'className' 'classSide' 'methodSource'
		                  'protocol' );
		               yourself.
	icons := {  }
]

{ #category : 'private' }
MCPToolCompileMethod >> methodReferenceFor: aBehavior selector: aSelector [

	^ String streamContents: [ :stream |
		  stream nextPutAll: (self targetNameFor: aBehavior).
		  stream nextPutAll: '>>'.
		  stream nextPutAll: aSelector asString ]
]

{ #category : 'private' }
MCPToolCompileMethod >> normalizedMethodSourceFrom: aMethodSource [

	^ aMethodSource withInternalLineEndings
]

{ #category : 'private' }
MCPToolCompileMethod >> targetNameFor: aBehavior [

	^ aBehavior isMeta
		  ifTrue: [ aBehavior instanceSide name , ' class' ]
		  ifFalse: [ aBehavior name ]
]
