Class {
	#name : 'MCPToolRenameClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRenameClass >> classSlotNamesOf: aClass [

	^ aClass classSide slots
		  collect: [ :each | each name asString ]
		  as: Array
]

{ #category : 'private' }
MCPToolRenameClass >> dataForRenamedClass: aClass oldClassName: anOldClassName [

	^ {
		  (#oldClassName -> anOldClassName).
		  (#newClassName -> aClass name asString).
		  (#superclassName -> (aClass superclass
			    ifNil: [ '' ]
			    ifNotNil: [ :superclass | superclass name asString ])).
		  (#packageName -> aClass packageName asString).
		  (#tag -> (self tagNameOf: aClass)).
		  (#instanceSlotNames -> (self instanceSlotNamesOf: aClass)).
		  (#classSlotNames -> (self classSlotNamesOf: aClass)).
		  (#subclassNames -> (self subclassNamesOf: aClass)) } asDictionary
]

{ #category : 'executing' }
MCPToolRenameClass >> executeWithArguments: arguments [

	| className newClassName renamedClass |
	className := arguments at: #className.
	newClassName := arguments at: #newClassName.
	^ [
	  self class environment
		  at: className asSymbol
		  ifAbsent: [ ^ self missingClassResultForClassName: className ].
	  (ReRenameClassRefactoring rename: className to: newClassName)
		  execute.
	  renamedClass := self class environment at: newClassName asSymbol.
	  self
		  successResultText:
		  (self successSummaryFrom: className to: newClassName)
		  data:
		  (self dataForRenamedClass: renamedClass oldClassName: className) ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultText: (self
						   failureMessageForClassNamed: className
						   to: newClassName
						   error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#className -> className).
						  (#newClassName -> newClassName) } asDictionary ]
]

{ #category : 'private' }
MCPToolRenameClass >> failureMessageForClassNamed: className to: newClassName error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to rename class ';
			  nextPutAll: className;
			  nextPutAll: ' to ';
			  nextPutAll: newClassName;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolRenameClass >> initialize [

	super initialize.
	name := 'pharo-rename-class'.
	title := 'Rename Pharo Class'.
	description := 'Rename a class in the running Pharo image using ReRenameClassRefactoring so references and subclass definitions are updated too.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description: 'The existing class name to rename.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'newClassName';
					                type: 'string';
					                description: 'The new class name to assign.';
					                yourself) };
		               required: #( 'className' 'newClassName' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'oldClassName'
					                 type: 'string'
					                 description: 'The class name before the rename.').
				                (self
					                 schemaPropertyNamed: 'newClassName'
					                 type: 'string'
					                 description: 'The class name after the rename.').
				                (self
					                 schemaPropertyNamed: 'superclassName'
					                 type: 'string'
					                 description:
					                 'The superclass of the renamed class.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owns the renamed class.').
				                (self
					                 schemaPropertyNamed: 'tag'
					                 type: 'string'
					                 description:
					                 'The package tag assigned to the renamed class.').
				                ((self
					                  schemaPropertyNamed: 'instanceSlotNames'
					                  type: 'array'
					                  description:
						                  'The instance-side slots present on the renamed class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'An instance-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'classSlotNames'
					                  type: 'array'
					                  description:
						                  'The class-side slots present on the renamed class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A class-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'subclassNames'
					                  type: 'array'
					                  description:
						                  'The direct subclasses of the renamed class after the refactoring.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A direct subclass name.';
							                  yourself);
					                 yourself) }
		                required:
			                #( 'oldClassName' 'newClassName' 'superclassName'
			                   'packageName' 'tag' 'instanceSlotNames'
			                   'classSlotNames' 'subclassNames' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolRenameClass >> instanceSlotNamesOf: aClass [

	^ aClass slots collect: [ :each | each name asString ] as: Array
]

{ #category : 'private' }
MCPToolRenameClass >> missingClassResultForClassName: className [

	| message |
	message := 'Class ' , className , ' does not exist.'.
	^ self errorResultText: message details: {
			  (#errorClass -> 'ClassNotFound').
			  (#message -> message).
			  (#className -> className) } asDictionary
]

{ #category : 'private' }
MCPToolRenameClass >> subclassNamesOf: aClass [

	^ (aClass subclasses
		   collect: [ :each | each name asString ]
		   as: Array) asSortedCollection asArray
]

{ #category : 'private' }
MCPToolRenameClass >> successSummaryFrom: className to: newClassName [

	^ 'Renamed class ' , className , ' to ' , newClassName , '.'
]

{ #category : 'private' }
MCPToolRenameClass >> tagNameOf: aClass [

	^ aClass packageTagName asString
]
