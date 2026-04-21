Class {
	#name : 'MCPToolRemoveClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRemoveClass >> applySafeRemovalOf: aClass withSnapshot: snapshot [

	| reparentedSubclassNames targetSuperclass |
	reparentedSubclassNames := snapshot at: #reparentedSubclassNames.
	reparentedSubclassNames ifNotEmpty: [
		targetSuperclass := aClass superclass.
		aClass subclasses do: [ :each | each superclass: targetSuperclass ] ].
	aClass removeFromSystem
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

{ #category : 'executing' }
MCPToolRemoveClass >> executeWithArguments: arguments [

	| className removedClass snapshot |
	className := arguments at: #className.
	^ [
	  removedClass := self class environment
		                  at: className asSymbol
		                  ifAbsent: [
		                  ^ self missingClassResultForClassName: className ].
	  self validateSafeRemovalOfClassNamed: className.
	  snapshot := self snapshotForRemovalOf: removedClass.
	  self applySafeRemovalOf: removedClass withSnapshot: snapshot.
	  self
		  successResultText: (self
				   successSummaryForClassName: className
				   reparentedSubclassNames:
				   (snapshot at: #reparentedSubclassNames))
		  data: snapshot ]
		  on: Exception
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
	description := 'Remove a class from the running Pharo image using ReRemoveClassRefactoring safety checks. Empty classes may be removed with subclasses by reparenting those subclasses to the removed class superclass.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'className';
				                type: 'string';
				                description: 'The class to remove.';
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
					                 'The superclass of the removed class before removal.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owned the removed class before removal.').
				                (self
					                 schemaPropertyNamed: 'tag'
					                 type: 'string'
					                 description:
					                 'The package tag that was assigned to the removed class before removal.').
				                (self
					                 schemaPropertyNamed: 'wasEmpty'
					                 type: 'boolean'
					                 description:
					                 'Whether the removed class was considered empty by the safe-removal rules.').
				                (self
					                 schemaPropertyNamed:
					                 'reparentedToSuperclassName'
					                 type: 'string'
					                 description:
					                 'The superclass that direct subclasses were reparented to when applicable.').
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
						                  'The direct subclasses that existed before removal.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A direct subclass name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'reparentedSubclassNames'
					                  type: 'array'
					                  description:
						                  'The direct subclasses that were reparented as part of the removal.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description:
								                  'A reparented direct subclass name.';
							                  yourself);
					                 yourself) }
		                required:
			                #( 'className' 'superclassName' 'packageName'
			                   'tag' 'wasEmpty' 'reparentedToSuperclassName'
			                   'instanceSlotNames' 'classSlotNames'
			                   'subclassNames' 'reparentedSubclassNames' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolRemoveClass >> instanceSlotNamesOf: aClass [

	^ aClass slots collect: [ :each | each name asString ] as: Array
]

{ #category : 'private' }
MCPToolRemoveClass >> isEmptyClass: aClass [

	^ aClass classVarNames isEmpty and: [
		  aClass instVarNames isEmpty and: [ aClass selectors isEmpty ] ]
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
MCPToolRemoveClass >> snapshotForRemovalOf: aClass [

	| subclassNames superclassName wasEmpty reparentedSubclassNames |
	subclassNames := self subclassNamesOf: aClass.
	superclassName := aClass superclass
		                  ifNil: [ '' ]
		                  ifNotNil: [ :superclass |
		                  superclass name asString ].
	wasEmpty := self isEmptyClass: aClass.
	reparentedSubclassNames := (wasEmpty and: [ aClass superclass notNil ])
		                           ifTrue: [ subclassNames ]
		                           ifFalse: [ #(  ) ].
	^ {
		  (#className -> aClass name asString).
		  (#superclassName -> superclassName).
		  (#packageName -> aClass packageName asString).
		  (#tag -> (self tagNameOf: aClass)).
		  (#wasEmpty -> wasEmpty).
		  (#reparentedToSuperclassName -> (reparentedSubclassNames isEmpty
			    ifTrue: [ '' ]
			    ifFalse: [ superclassName ])).
		  (#instanceSlotNames -> (self instanceSlotNamesOf: aClass)).
		  (#classSlotNames -> (self classSlotNamesOf: aClass)).
		  (#subclassNames -> subclassNames).
		  (#reparentedSubclassNames -> reparentedSubclassNames) }
		  asDictionary
]

{ #category : 'private' }
MCPToolRemoveClass >> subclassNamesOf: aClass [

	^ (aClass subclasses
		   collect: [ :each | each name asString ]
		   as: Array) asSortedCollection asArray
]

{ #category : 'private' }
MCPToolRemoveClass >> successSummaryForClassName: className reparentedSubclassNames: reparentedSubclassNames [

	^ reparentedSubclassNames isEmpty
		  ifTrue: [ 'Removed class ' , className , '.' ]
		  ifFalse: [
			  'Removed class ' , className , ' and reparented subclasses: '
			  , (', ' join: reparentedSubclassNames) , '.' ]
]

{ #category : 'private' }
MCPToolRemoveClass >> tagNameOf: aClass [

	^ aClass packageTagName asString
]

{ #category : 'private' }
MCPToolRemoveClass >> validateSafeRemovalOfClassNamed: className [

	| refactoring |
	refactoring := ReRemoveClassRefactoring classNames: { className }.
	refactoring prepareForExecution.
	refactoring checkPreconditions
]
