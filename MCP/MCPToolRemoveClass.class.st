Class {
	#name : 'MCPToolRemoveClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRemoveClass >> classFromArguments: arguments [

	^ self class environment at:
		  (self classNameSymbolFromArguments: arguments)
]

{ #category : 'private' }
MCPToolRemoveClass >> classNameSymbolFromArguments: arguments [

	^ (arguments at: #className) asSymbol
]

{ #category : 'private' }
MCPToolRemoveClass >> classSlotNamesOf: aClass [

	^ aClass classSide slots
		  collect: [ :each | each name asString ]
		  as: Array
]

{ #category : 'private' }
MCPToolRemoveClass >> dataForClass: aClass subclassNames: subclassNames [

	^ {
		  (#className -> aClass name asString).
		  (#superclassName -> (aClass superclass
			    ifNil: [ '' ]
			    ifNotNil: [ :superclass | superclass name asString ])).
		  (#packageName -> aClass packageName asString).
		  (#tag -> (self tagNameOf: aClass)).
		  (#instanceSlotNames -> (self instanceSlotNamesOf: aClass)).
		  (#classSlotNames -> (self classSlotNamesOf: aClass)).
		  (#subclassNames -> subclassNames) } asDictionary
]

{ #category : 'executing' }
MCPToolRemoveClass >> executeWithArguments: arguments [

	| className removedClass subclassNames data |
	className := arguments at: #className.
	^ [
	  removedClass := self class environment
		                  at: className asSymbol
		                  ifAbsent: [
		                  ^ self missingClassResultForClassName: className ].
	  subclassNames := self subclassNamesOf: removedClass.
	  subclassNames ifNotEmpty: [
		  ^ self
			    subclassesPreventRemovalResultForClass: removedClass
			    subclassNames: subclassNames ].
	  data := self
		          dataForClass: removedClass
		          subclassNames: subclassNames.
	  removedClass removeFromSystem.
	  self
		  successResultText: (self successSummaryForClass: removedClass)
		  data: data ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultText:
				  (self failureMessageForClassNamed: className error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#className -> className) } asDictionary ]
]

{ #category : 'private' }
MCPToolRemoveClass >> failureMessageForClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to remove class ';
			  nextPutAll: className;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolRemoveClass >> initialize [

	super initialize.
	name := 'pharo-remove-class'.
	title := 'Remove Pharo Class'.
	description := 'Remove a class from the running Pharo image and return structured information about what was removed. Removal is rejected when the class still has subclasses.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'className';
				                type: 'string';
				                description: 'The name of the class to remove.';
				                yourself) };
		               required: #( 'className' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description: 'The class that was removed.').
				                (self
					                 schemaPropertyNamed: 'superclassName'
					                 type: 'string'
					                 description:
					                 'The superclass of the removed class.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owned the removed class.').
				                (self
					                 schemaPropertyNamed: 'tag'
					                 type: 'string'
					                 description:
					                 'The package tag that was assigned to the removed class.').
				                ((self
					                  schemaPropertyNamed: 'instanceSlotNames'
					                  type: 'array'
					                  description:
						                  'The instance-side slots that were present on the removed class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'An instance-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'classSlotNames'
					                  type: 'array'
					                  description:
						                  'The class-side slots that were present on the removed class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A class-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'subclassNames'
					                  type: 'array'
					                  description:
						                  'The direct subclasses that existed at removal time. This is empty for successful removals.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A direct subclass name.';
							                  yourself);
					                 yourself) }
		                required:
			                #( 'className' 'superclassName' 'packageName'
			                   'tag' 'instanceSlotNames' 'classSlotNames'
			                   'subclassNames' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolRemoveClass >> instanceSlotNamesOf: aClass [

	^ aClass slots collect: [ :each | each name asString ] as: Array
]

{ #category : 'private' }
MCPToolRemoveClass >> missingClassResultForClassName: className [

	| message |
	message := 'Class ' , className , ' does not exist.'.
	^ self errorResultText: message details: {
			  (#errorClass -> 'ClassNotFound').
			  (#message -> message).
			  (#className -> className) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveClass >> subclassNamesOf: aClass [

	^ (aClass subclasses
		   collect: [ :each | each name asString ]
		   as: Array) asSortedCollection asArray
]

{ #category : 'private' }
MCPToolRemoveClass >> subclassesPreventRemovalResultForClass: aClass subclassNames: subclassNames [

	| message |
	message := String streamContents: [ :stream |
		           stream
			           nextPutAll: 'Cannot remove class ';
			           nextPutAll: aClass name;
			           nextPutAll: ' because it still has subclasses: ';
			           nextPutAll: (', ' join: subclassNames) ].
	^ self errorResultText: message details: {
			  (#errorClass -> 'ClassHasSubclasses').
			  (#message -> message).
			  (#className -> aClass name asString).
			  (#subclassNames -> subclassNames) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveClass >> successSummaryForClass: aClass [

	^ 'Removed class ' , aClass name asString , '.'
]

{ #category : 'private' }
MCPToolRemoveClass >> tagNameOf: aClass [

	^ aClass packageTagName asString
]
