Class {
	#name : 'MCPToolMoveClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolMoveClass >> classSlotNamesOf: aClass [

	^ aClass classSide slots
		  collect: [ :each | each name asString ]
		  as: Array
]

{ #category : 'private' }
MCPToolMoveClass >> dataForClass: aClass oldPackageName: oldPackageName oldTag: oldTag [

	^ {
		  (#className -> aClass name asString).
		  (#superclassName -> (aClass superclass
			    ifNil: [ '' ]
			    ifNotNil: [ :superclass | superclass name asString ])).
		  (#oldPackageName -> oldPackageName).
		  (#packageName -> aClass packageName asString).
		  (#oldTag -> oldTag).
		  (#tag -> (self tagNameOf: aClass)).
		  (#instanceSlotNames -> (self instanceSlotNamesOf: aClass)).
		  (#classSlotNames -> (self classSlotNamesOf: aClass)).
		  (#subclassNames -> (self subclassNamesOf: aClass)) } asDictionary
]

{ #category : 'private' }
MCPToolMoveClass >> destinationValidationResultForClassNamed: className packageName: packageName tag: tag [

	| package |
	(self packageOrganizer hasPackage: packageName) ifFalse: [
		^ self
			  missingPackageResultForClassNamed: className
			  packageName: packageName ].
	tag ifNil: [ ^ nil ].
	package := self packageOrganizer packageNamed: packageName.
	(package hasTag: tag) ifFalse: [
		^ self
			  missingTagResultForClassNamed: className
			  packageName: packageName
			  tag: tag ].
	^ nil
]

{ #category : 'private' }
MCPToolMoveClass >> destinationValidationResultForPackageName: packageName tag: tag [

	| package |
	(self packageOrganizer hasPackage: packageName) ifFalse: [
		^ self missingPackageResultForPackageName: packageName ].
	tag ifNil: [ ^ nil ].
	package := self packageOrganizer packageNamed: packageName.
	(package hasTag: tag) ifFalse: [
		^ self missingTagResultForPackageName: packageName tag: tag ].
	^ nil
]

{ #category : 'executing' }
MCPToolMoveClass >> executeWithArguments: arguments [

	| className movedClass oldPackageName oldTag packageName tag validationResult |
	className := arguments at: #className.
	packageName := arguments at: #packageName.
	tag := self tagFromArguments: arguments.
	^ [
	  movedClass := self class environment
		                at: className asSymbol
		                ifAbsent: [
		                ^ self missingClassResultForClassName: className ].
	  validationResult := self
		                      destinationValidationResultForClassNamed:
		                      className
		                      packageName: packageName
		                      tag: tag.
	  validationResult ifNotNil: [ ^ validationResult ].
	  oldPackageName := movedClass packageName asString.
	  oldTag := self tagNameOf: movedClass.
	  self performMoveOf: className toPackage: packageName tag: tag.
	  movedClass := self class environment at: className asSymbol.
	  self
		  successResultText: (self
				   successSummaryForClass: movedClass
				   packageName: packageName
				   tag: tag)
		  data: (self
				   dataForClass: movedClass
				   oldPackageName: oldPackageName
				   oldTag: oldTag) ]
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
MCPToolMoveClass >> instanceSlotNamesOf: aClass [

	^ aClass slots collect: [ :each | each name asString ] as: Array
]

{ #category : 'private' }
MCPToolMoveClass >> missingClassResultForClassName: className [

	| message |
	message := 'Class ' , className , ' does not exist.'.
	^ self errorResultText: message details: {
			  (#errorClass -> 'ClassNotFound').
			  (#message -> message).
			  (#className -> className) } asDictionary
]

{ #category : 'private' }
MCPToolMoveClass >> missingPackageResultForClassNamed: className packageName: packageName [

	| message |
	message := 'Package ' , packageName , ' does not exist.'.
	^ self errorResultText: message details: {
			  (#errorClass -> 'PackageNotFound').
			  (#message -> message).
			  (#className -> className).
			  (#packageName -> packageName) } asDictionary
]

{ #category : 'private' }
MCPToolMoveClass >> missingPackageResultForPackageName: packageName [

	| message |
	message := 'Package ' , packageName , ' does not exist.'.
	^ self errorResultText: message details: {
			  (#errorClass -> 'PackageNotFound').
			  (#message -> message).
			  (#packageName -> packageName) } asDictionary
]

{ #category : 'private' }
MCPToolMoveClass >> missingTagResultForClassNamed: className packageName: packageName tag: tag [

	| message |
	message := 'Package ' , packageName , ' does not have a tag named '
	           , tag , '.'.
	^ self errorResultText: message details: {
			  (#errorClass -> 'TagNotFound').
			  (#message -> message).
			  (#className -> className).
			  (#packageName -> packageName).
			  (#tag -> tag) } asDictionary
]

{ #category : 'private' }
MCPToolMoveClass >> missingTagResultForPackageName: packageName tag: tag [

	| message |
	message := 'Package ' , packageName , ' does not have a tag named '
	           , tag , '.'.
	^ self errorResultText: message details: {
			  (#errorClass -> 'TagNotFound').
			  (#message -> message).
			  (#packageName -> packageName).
			  (#tag -> tag) } asDictionary
]

{ #category : 'private' }
MCPToolMoveClass >> performMoveOf: className toPackage: packageName tag: tag [

	tag
		ifNil: [
			(RBMoveClassTransformation move: className toPackage: packageName)
				execute ]
		ifNotNil: [
			(RBMoveClassTransformation
				 move: className
				 toPackage: packageName
				 inTag: tag) execute ]
]

{ #category : 'private' }
MCPToolMoveClass >> subclassNamesOf: aClass [

	^ (aClass subclasses
		   collect: [ :each | each name asString ]
		   as: Array) asSortedCollection asArray
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

{ #category : 'private' }
MCPToolMoveClass >> tagNameOf: aClass [

	^ aClass packageTagName asString
]
