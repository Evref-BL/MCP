Class {
	#name : 'MCPToolChangeMethodProtocol',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolChangeMethodProtocol >> dataForCompiledMethod: aCompiledMethod className: className classSide: classSide oldProtocol: oldProtocol [

	| info |
	info := MCPCompiledMethodInfo fromCompiledMethod: aCompiledMethod.
	^ {
		  (#className -> className).
		  (#classSide -> classSide).
		  (#selector -> info selector).
		  (#oldProtocol -> oldProtocol).
		  (#protocol -> info protocol).
		  (#packageName -> info packageName).
		  (#isExtension -> info isExtension).
		  (#source -> info source).
		  (#methodReference -> info methodReference) } asDictionary
]

{ #category : 'private' }
MCPToolChangeMethodProtocol >> errorResultForError: anError className: className classSide: classSide selector: selector protocol: protocol [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultText: anError messageText
			  details: anError structuredDetails ].
	^ self
		  errorResultText: (self
				   failureMessageForClassNamed: className
				   classSide: classSide
				   selector: selector
				   protocol: protocol
				   error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#className -> className).
				  (#classSide -> classSide).
				  (#selector -> selector).
				  (#protocol -> protocol) } asDictionary
]

{ #category : 'executing' }
MCPToolChangeMethodProtocol >> executeWithArguments: arguments [

	| behavior className classSide compiledMethod newCompiledMethod oldProtocol protocol selector selectorSymbol |
	className := arguments at: #className.
	classSide := arguments at: #classSide.
	selector := arguments at: #selector.
	protocol := arguments at: #protocol.
	selectorSymbol := selector asSymbol.
	^ [
	  behavior := self behaviorNamed: className classSide: classSide.
	  compiledMethod := behavior
		                    compiledMethodAt: selectorSymbol
		                    ifAbsent: [
			                    MCPCommandError
				                    signalMissingMethodInClassName: className
				                    classSide: classSide
				                    selector: selector ].
	  oldProtocol := (MCPCompiledMethodInfo fromCompiledMethod:
		                  compiledMethod) protocol.
	  (RBMethodProtocolTransformation
		   protocol: protocol
		   inMethod: selectorSymbol
		   inClass:
		   (self transformationClassNameFor: className classSide: classSide))
		  execute.
	  newCompiledMethod := behavior compiledMethodAt: selectorSymbol.
	  self
		  successResultText: 'Changed protocol for '
			  ,
			  (self
				   methodReferenceForBehavior: behavior
				   selector: selectorSymbol) , '.'
		  data: (self
				   dataForCompiledMethod: newCompiledMethod
				   className: className
				   classSide: classSide
				   oldProtocol: oldProtocol) ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForError: error
				  className: className
				  classSide: classSide
				  selector: selector
				  protocol: protocol ]
]

{ #category : 'private' }
MCPToolChangeMethodProtocol >> failureMessageForClassNamed: className classSide: classSide selector: selector protocol: protocol error: anError [

	| targetName |
	targetName := classSide
		              ifTrue: [ className , ' class' ]
		              ifFalse: [ className ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to change protocol for ';
			  nextPutAll: targetName;
			  nextPutAll: '>>';
			  nextPutAll: selector;
			  nextPutAll: ' to ';
			  nextPutAll: protocol;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolChangeMethodProtocol >> initialize [

	super initialize.
	name := 'pharo-change-method-protocol'.
	title := 'Change Pharo Method Protocol'.
	description := 'Change the protocol of a method on the instance side or class side of a Pharo class using RBMethodProtocolTransformation. This can also move methods into extension protocols.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description:
						                'The class that defines the method whose protocol will change.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'classSide';
					                type: 'boolean';
					                description:
						                'Whether the method is defined on the class side.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'selector';
					                type: 'string';
					                description:
						                'The selector of the method whose protocol will change.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'protocol';
					                type: 'string';
					                description:
						                'The new method protocol to assign, including extension protocols.';
					                yourself) };
		               required:
		               #( 'className' 'classSide' 'selector' 'protocol' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description:
					                 'The class whose method protocol changed.').
				                (self
					                 schemaPropertyNamed: 'classSide'
					                 type: 'boolean'
					                 description:
					                 'Whether the method is on the class side.').
				                (self
					                 schemaPropertyNamed: 'selector'
					                 type: 'string'
					                 description:
					                 'The selector whose protocol changed.').
				                (self
					                 schemaPropertyNamed: 'oldProtocol'
					                 type: 'string'
					                 description:
					                 'The method protocol before the change.').
				                (self
					                 schemaPropertyNamed: 'protocol'
					                 type: 'string'
					                 description:
					                 'The method protocol after the change.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owns the method after the protocol change.').
				                (self
					                 schemaPropertyNamed: 'isExtension'
					                 type: 'boolean'
					                 description:
					                 'Whether the method is an extension method after the protocol change.').
				                (self
					                 schemaPropertyNamed: 'source'
					                 type: 'string'
					                 description:
					                 'The method source after the protocol change.').
				                (self
					                 schemaPropertyNamed: 'methodReference'
					                 type: 'string'
					                 description:
					                 'A readable method reference for the affected method.') }
		                required:
			                #( 'className' 'classSide' 'selector' 'oldProtocol'
			                   'protocol' 'packageName' 'isExtension'
			                   'source' 'methodReference' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolChangeMethodProtocol >> transformationClassNameFor: className classSide: classSide [

	^ classSide
		  ifTrue: [ className , ' class' ]
		  ifFalse: [ className ]
]
