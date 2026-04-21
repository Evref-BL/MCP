Class {
	#name : 'MCPToolMoveClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolMoveClass >> executeWithArguments: arguments [

	| className movedClass packageName result tag |
	className := arguments at: #className.
	packageName := arguments at: #packageName.
	tag := self tagFromArguments: arguments.
	^ [
	  [
	  result := (MCPMoveClassCommand
		             className: className
		             packageName: packageName
		             tag: tag) execute.
	  movedClass := Smalltalk globals at: className asSymbol.
	  self
		  successResultText: (self
				   successSummaryForClass: movedClass
				   packageName: packageName
				   tag: tag)
		  data: result asDictionary ]
		  on: MCPCommandError
		  do: [ :error |
			  self
				  errorResultText: error messageText
				  details: error structuredDetails ] ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultText: (self
						   failureMessageForClassNamed: className
						   packageName: packageName
						   tag: tag
						   error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#className -> className).
						  (#packageName -> packageName).
						  (#tag -> (tag ifNil: [ '' ] ifNotNil: [ tag ])) } asDictionary ]
]

{ #category : 'private' }
MCPToolMoveClass >> failureMessageForClassNamed: className packageName: packageName tag: tag error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to move class ';
			  nextPutAll: className;
			  nextPutAll: ' to package ';
			  nextPutAll: packageName.
		  tag ifNotNil: [
			  stream
				  nextPutAll: ' tag ';
				  nextPutAll: tag ].
		  stream
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolMoveClass >> initialize [

	super initialize.
	name := 'pharo-move-class'.
	title := 'Move Pharo Class'.
	description := 'Move a class to another package or package tag in the running Pharo image using RBMoveClassTransformation. The destination package, and optional tag, must already exist.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description: 'The class to move.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'packageName';
					                type: 'string';
					                description:
						                'The destination package that should receive the class.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'tag';
					                type: 'string';
					                description:
						                'An optional destination package tag. The tag must already exist in the destination package.';
					                yourself) };
		               required: #( 'className' 'packageName' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description: 'The class that was moved.').
				                (self
					                 schemaPropertyNamed: 'superclassName'
					                 type: 'string'
					                 description:
					                 'The superclass of the moved class.').
				                (self
					                 schemaPropertyNamed: 'oldPackageName'
					                 type: 'string'
					                 description:
					                 'The package that owned the class before the move.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owns the class after the move.').
				                (self
					                 schemaPropertyNamed: 'oldTag'
					                 type: 'string'
					                 description:
					                 'The package tag assigned to the class before the move.').
				                (self
					                 schemaPropertyNamed: 'tag'
					                 type: 'string'
					                 description:
					                 'The package tag assigned to the class after the move.').
				                ((self
					                  schemaPropertyNamed: 'instanceSlotNames'
					                  type: 'array'
					                  description:
						                  'The instance-side slots present on the moved class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'An instance-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'classSlotNames'
					                  type: 'array'
					                  description:
						                  'The class-side slots present on the moved class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A class-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'subclassNames'
					                  type: 'array'
					                  description:
						                  'The direct subclasses of the moved class after the move.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A direct subclass name.';
							                  yourself);
					                 yourself) }
		                required:
			                #( 'className' 'superclassName' 'oldPackageName'
			                   'packageName' 'oldTag' 'tag' 'instanceSlotNames'
			                   'classSlotNames' 'subclassNames' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolMoveClass >> successSummaryForClass: aClass packageName: packageName tag: tag [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Moved class ';
			  nextPutAll: aClass name asString;
			  nextPutAll: ' to package ';
			  nextPutAll: packageName.
		  tag ifNotNil: [
			  stream
				  nextPutAll: ' tag ';
				  nextPutAll: tag ].
		  stream nextPutAll: '.' ]
]

{ #category : 'private' }
MCPToolMoveClass >> tagFromArguments: arguments [

	| tag |
	tag := self stringArgumentNamed: 'tag' in: arguments.
	^ tag ifNil: [ nil ] ifNotNil: [ tag ]
]
