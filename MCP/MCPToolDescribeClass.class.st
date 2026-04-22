Class {
	#name : 'MCPToolDescribeClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - schema' }
MCPToolDescribeClass >> classDescriptionDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'The described class.').
		  (self
			   schemaPropertyNamed: 'superclassName'
			   type: 'string'
			   description:
			   'The direct superclass of the described class, or an empty string for the root.').
		  (self
			   schemaPropertyNamed: 'packageName'
			   type: 'string'
			   description: 'The package that defines the class.').
		  (self
			   schemaPropertyNamed: 'tag'
			   type: 'string'
			   description: 'The package tag assigned to the class.').
		  (self
			   stringArraySchemaNamed: 'instanceSlotNames'
			   description: 'The instance-side slots defined on the class.'
			   itemDescription: 'An instance-side slot name.').
		  (self
			   stringArraySchemaNamed: 'classSlotNames'
			   description: 'The class-side slots defined on the class.'
			   itemDescription: 'A class-side slot name.').
		  (self
			   stringArraySchemaNamed: 'traitNames'
			   description: 'The traits used by the class.'
			   itemDescription: 'A trait name.').
		  (self
			   stringArraySchemaNamed: 'classTraitNames'
			   description: 'The traits used by the class side.'
			   itemDescription: 'A class-side trait name.').
		  (self
			   stringArraySchemaNamed: 'sharedPoolNames'
			   description: 'The shared pools referenced by the class.'
			   itemDescription: 'A shared pool name.').
		  (self
			   integerSchemaPropertyNamed: 'instanceMethodCount'
			   description:
			   'The number of instance-side methods defined on the class.').
		  (self
			   integerSchemaPropertyNamed: 'classMethodCount'
			   description:
			   'The number of class-side methods defined on the class.') }
]

{ #category : 'private - schema' }
MCPToolDescribeClass >> classDescriptionObjectSchema [

	^ MCPStructureProperties new
		  name: 'classDescription';
		  type: 'object';
		  description: 'Structured metadata for one class in the hierarchy.';
		  properties: self classDescriptionDataProperties;
		  required: self classDescriptionRequiredFields;
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolDescribeClass >> classDescriptionRequiredFields [

	^ #( 'className' 'superclassName' 'packageName' 'tag' 'instanceSlotNames'
	     'classSlotNames' 'traitNames' 'classTraitNames'
	     'sharedPoolNames' 'instanceMethodCount' 'classMethodCount' )
]

{ #category : 'private - arguments' }
MCPToolDescribeClass >> classNameFromArguments: arguments [

	| className |
	className := self stringArgumentNamed: 'className' in: arguments.
	className ifNil: [
		Error signal: 'className must be a non-empty string.' ].
	^ className
]

{ #category : 'private - hierarchy' }
MCPToolDescribeClass >> descriptionDictionariesForClasses: someClasses [

	^ (someClasses collect: [ :each |
		   (MCPClassDescription fromClass: each) asDictionary ]) asArray
]

{ #category : 'private' }
MCPToolDescribeClass >> errorResultForError: anError className: className [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultText: anError messageText
			  details: anError structuredDetails ].
	^ self
		  errorResultText:
		  (self failureMessageForClassName: className error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#className -> className) } asDictionary
]

{ #category : 'executing' }
MCPToolDescribeClass >> executeWithArguments: arguments [

	| className data describedClass subclasses superclasses |
	className := self classNameFromArguments: arguments.
	^ [
	  describedClass := self resolvedClassNamed: className.
	  superclasses := self
		                  superclassesForClass: describedClass
		                  arguments: arguments.
	  subclasses := self
		                subclassesForClass: describedClass
		                arguments: arguments.
	  data := (MCPClassDescription fromClass: describedClass)
		          asDictionary copy.
	  data
		  at: #superclasses
		  put: (self descriptionDictionariesForClasses: superclasses).
	  data
		  at: #subclasses
		  put: (self descriptionDictionariesForClasses: subclasses).
	  self
		  successResultText: (self
				   successSummaryForClassName: className
				   superclasses: superclasses
				   subclasses: subclasses)
		  data: data ]
		  on: Exception
		  do: [ :error |
		  self errorResultForError: error className: className ]
]

{ #category : 'private' }
MCPToolDescribeClass >> failureMessageForClassName: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to describe class ';
			  nextPutAll: className;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolDescribeClass >> initialize [

	| includeSuperclassesProperty subclassDepthProperty upToSuperclassNameProperty |
	super initialize.
	name := 'describe-class'.
	title := 'Describe Pharo Class'.
	description := 'Inspect one class by name and return structured metadata, with optional superclass and subclass context. Use find-classes to discover candidate classes first.'.
	includeSuperclassesProperty := MCPStructureProperties new
		                               name: 'includeSuperclasses';
		                               type: 'boolean';
		                               description:
			                               'Whether to include superclass descriptions. Defaults to false.';
		                               yourself.
	upToSuperclassNameProperty := MCPStructureProperties new
		                              name: 'upToSuperclassName';
		                              type: 'string';
		                              description:
			                              'An optional superclass name that stops the included superclass chain at a specific ancestor. If the named class is not actually an ancestor, the chain continues to the root.';
		                              yourself.
	subclassDepthProperty := MCPStructureProperties new
		                         name: 'subclassDepth';
		                         type: 'integer';
		                         description:
			                         'How many subclass levels to include. Uses 0 by default, 1 for direct subclasses, 2 for grandchildren too, and so on.';
		                         yourself.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description: 'The class to describe.';
					                yourself).
				               includeSuperclassesProperty.
				               upToSuperclassNameProperty.
				               subclassDepthProperty };
		               required: #( 'className' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties:
			                self classDescriptionDataProperties , {
				                ((self
					                  schemaPropertyNamed: 'superclasses'
					                  type: 'array'
					                  description:
						                  'The included superclasses, starting from the direct superclass and moving upward.')
					                 items: self classDescriptionObjectSchema;
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'subclasses'
					                  type: 'array'
					                  description:
						                  'The included subclasses or descendants of the described class, bounded by subclassDepth.')
					                 items: self classDescriptionObjectSchema;
					                 yourself) }
		                required:
		                self classDescriptionRequiredFields
		                , #( 'superclasses' 'subclasses' ).
	icons := { (self
		          pngCompositeBaseIconNamed: #class
		          badgeIconNamed: #inspect) }
]

{ #category : 'private - hierarchy' }
MCPToolDescribeClass >> resolvedClassNamed: className [

	^ Smalltalk globals
		  at: className asSymbol
		  ifAbsent: [ MCPCommandError signalMissingClassNamed: className ]
]

{ #category : 'private - hierarchy' }
MCPToolDescribeClass >> sortedClassesByName: someClasses [

	^ (someClasses asSortedCollection: [ :left :right |
		   left name <= right name ]) asArray
]

{ #category : 'private - hierarchy' }
MCPToolDescribeClass >> subclassesForClass: aClass arguments: arguments [

	| subclassDepth subclasses |
	subclassDepth := self
		                 nonNegativeIntegerArgumentNamed: 'subclassDepth'
		                 in: arguments
		                 default: 0.
	subclassDepth = 0 ifTrue: [ ^ #(  ) ].
	subclasses := OrderedCollection new.
	aClass
		allSubclassesWithLevelDo: [ :eachClass :level |
			(level between: 1 and: subclassDepth) ifTrue: [
				subclasses add: eachClass ] ]
		startingLevel: 0.
	^ subclasses asArray
]

{ #category : 'private' }
MCPToolDescribeClass >> successSummaryForClassName: className superclasses: superclasses subclasses: subclasses [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Described class ';
			  nextPutAll: className;
			  nextPut: $..
		  (superclasses isEmpty and: [ subclasses isEmpty ]) ifFalse: [
			  stream
				  space;
				  nextPutAll: 'Included ';
				  print: superclasses size;
				  nextPutAll: ' superclass';
				  nextPutAll: (superclasses size = 1
						   ifTrue: [ '' ]
						   ifFalse: [ 'es' ]);
				  nextPutAll: ' and ';
				  print: subclasses size;
				  nextPutAll: ' subclass';
				  nextPutAll: (subclasses size = 1
						   ifTrue: [ '' ]
						   ifFalse: [ 'es' ]);
				  nextPut: $. ] ]
]

{ #category : 'private - hierarchy' }
MCPToolDescribeClass >> superclassesForClass: aClass arguments: arguments [

	| includeSuperclasses targetSuperclass targetSuperclassName |
	includeSuperclasses := self
		                       booleanArgumentNamed: 'includeSuperclasses'
		                       in: arguments
		                       default: false.
	targetSuperclassName := self
		                        stringArgumentNamed: 'upToSuperclassName'
		                        in: arguments.
	(includeSuperclasses not and: [ targetSuperclassName isNil ])
		ifTrue: [ ^ #(  ) ].
	targetSuperclassName ifNil: [ ^ aClass allSuperclasses asArray ].
	targetSuperclass := Smalltalk globals
		                    at: targetSuperclassName asSymbol
		                    ifAbsent: [
			                    MCPCommandError
				                    signalMissingSuperclassNamed:
				                    targetSuperclassName
				                    forClassNamed: aClass name asString ].
	^ (aClass allSuperclassesIncluding: targetSuperclass) asArray
]
