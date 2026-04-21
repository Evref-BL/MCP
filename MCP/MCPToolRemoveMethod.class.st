Class {
	#name : 'MCPToolRemoveMethod',
	#superclass : 'MCPToolCompileMethod',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRemoveMethod >> classPackageNameForCompiledMethod: aCompiledMethod [

	^ aCompiledMethod methodClass instanceSide package name asString
]

{ #category : 'executing' }
MCPToolRemoveMethod >> executeWithArguments: arguments [

	| behavior className classSide compiledMethod data methodReference packageName protocolName selector selectorString sourceText |
	className := arguments at: #className.
	classSide := arguments at: #classSide.
	selectorString := arguments at: #selector.
	behavior := self behaviorFromArguments: arguments.
	selector := selectorString asSymbol.
	compiledMethod := behavior compiledMethodAt: selector ifAbsent: [
		                  ^ self
			                    missingMethodResultForClassName: className
			                    classSide: classSide
			                    selector: selectorString ].
	protocolName := self protocolNameForCompiledMethod: compiledMethod.
	sourceText := compiledMethod sourceCode ifNil: [ '' ].
	packageName := self packageNameForCompiledMethod: compiledMethod.
	methodReference := self
		                   methodReferenceFor: behavior
		                   selector: selector.
	behavior removeSelector: selector.
	data := {
		        (#className -> className).
		        (#classSide -> classSide).
		        (#selector -> selectorString).
		        (#protocol -> protocolName).
		        (#packageName -> packageName).
		        (#isExtension
		         -> (self isExtensionCompiledMethod: compiledMethod)).
		        (#source -> sourceText).
		        (#methodReference -> methodReference) } asDictionary.
	^ self
		  successResultText: 'Removed ' , methodReference , '.'
		  data: data
]

{ #category : 'initialization' }
MCPToolRemoveMethod >> initialize [

	super initialize.
	name := 'pharo-remove-method'.
	title := 'Remove Pharo Method'.
	description := 'Remove a method from the instance side or class side of a Pharo class and return structured information about what was removed.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description:
						                'The name of the class from which the method will be removed.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'classSide';
					                type: 'boolean';
					                description:
						                'Whether to remove from the class side (true) or instance side (false).';
					                yourself).
				               (MCPStructureProperties new
					                name: 'selector';
					                type: 'string';
					                description:
						                'The selector of the method to remove.';
					                yourself) };
		               required: #( 'className' 'classSide' 'selector' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description:
					                 'The class from which the method was removed.').
				                (self
					                 schemaPropertyNamed: 'classSide'
					                 type: 'boolean'
					                 description:
					                 'Whether the removed method was on the class side.').
				                (self
					                 schemaPropertyNamed: 'selector'
					                 type: 'string'
					                 description: 'The selector that was removed.').
				                (self
					                 schemaPropertyNamed: 'protocol'
					                 type: 'string'
					                 description:
					                 'The protocol that contained the removed method.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owned the removed method.').
				                (self
					                 schemaPropertyNamed: 'isExtension'
					                 type: 'boolean'
					                 description:
					                 'Whether the removed method was an extension method.').
				                (self
					                 schemaPropertyNamed: 'source'
					                 type: 'string'
					                 description:
					                 'The source code of the removed method.').
				                (self
					                 schemaPropertyNamed: 'methodReference'
					                 type: 'string'
					                 description:
					                 'A readable method reference for the removed method.') }
		                required:
			                #( 'className' 'classSide' 'selector' 'protocol'
			                   'packageName' 'isExtension' 'source' 'methodReference' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolRemoveMethod >> isExtensionCompiledMethod: aCompiledMethod [

	^ (self packageNameForCompiledMethod: aCompiledMethod)
	  ~= (self classPackageNameForCompiledMethod: aCompiledMethod)
]

{ #category : 'private' }
MCPToolRemoveMethod >> missingMethodResultForClassName: className classSide: classSide selector: selectorString [

	| methodReference message |
	methodReference := classSide
		                   ifTrue: [
		                   className , ' class>>' , selectorString ]
		                   ifFalse: [ className , '>>' , selectorString ].
	message := 'Method ' , methodReference , ' does not exist.'.
	^ self errorResultText: message details: {
			  (#errorClass -> 'MethodNotFound').
			  (#message -> message).
			  (#className -> className).
			  (#classSide -> classSide).
			  (#selector -> selectorString).
			  (#methodReference -> methodReference) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveMethod >> packageNameForCompiledMethod: aCompiledMethod [

	| package |
	package := aCompiledMethod package ifNil: [
		           aCompiledMethod methodClass instanceSide package ].
	^ package name asString
]

{ #category : 'private' }
MCPToolRemoveMethod >> protocolNameForCompiledMethod: aCompiledMethod [

	^ aCompiledMethod protocol
		  ifNil: [ '' ]
		  ifNotNil: [ :protocol | protocol name asString ]
]
