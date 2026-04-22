Class {
	#name : 'MCPToolInspectClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - schema' }
MCPToolInspectClass >> classDescriptionDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'The inspected class.').
		  (self
			   schemaPropertyNamed: 'superclassName'
			   type: 'string'
			   description:
			   'The direct superclass of the inspected class, or an empty string for the root.').
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
			   'The number of class-side methods defined on the class.').
		  (self
			   schemaPropertyNamed: 'classComment'
			   type: 'string'
			   description: 'The class comment when includeComment=true.') }
]

{ #category : 'private - schema' }
MCPToolInspectClass >> classDescriptionObjectSchema [

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
MCPToolInspectClass >> classDescriptionRequiredFields [

	^ #( 'className' 'superclassName' 'packageName' 'tag' 'instanceSlotNames'
	     'classSlotNames' 'traitNames' 'classTraitNames'
	     'sharedPoolNames' 'instanceMethodCount' 'classMethodCount' )
]

{ #category : 'private - arguments' }
MCPToolInspectClass >> classNameFromArguments: arguments [

	| className |
	className := self stringArgumentNamed: 'className' in: arguments.
	className ifNil: [
		Error signal: 'className must be a non-empty string.' ].
	^ className
]

{ #category : 'defaults' }
MCPToolInspectClass >> defaultDescription [

	^ 'Inspect one class by name and return structured metadata, with optional superclass and subclass context. Use find-classes to discover candidate classes first.'
]

{ #category : 'defaults' }
MCPToolInspectClass >> defaultIcons [

	^ { (self
		          pngCompositeBaseIconNamed: #class
		          badgeIconNamed: #inspect) }
]

{ #category : 'defaults' }
MCPToolInspectClass >> defaultInputSchema [

	| includeSuperclassesProperty includeCommentProperty upToSuperclassNameProperty subclassDepthProperty |
	includeSuperclassesProperty := MCPStructureProperties new
		                               name: 'includeSuperclasses';
		                               type: 'boolean';
		                               description:
			                               'Whether to include superclass descriptions. Defaults to false.';
		                               default: false;
		                               yourself.
	includeCommentProperty := MCPStructureProperties new
		                          name: 'includeComment';
		                          type: 'boolean';
		                          description:
			                          'Whether to include the class comment in returned class descriptions. Defaults to false.';
		                          default: false;
		                          yourself.
	upToSuperclassNameProperty := MCPStructureProperties new
		                              name: 'upToSuperclassName';
		                              type: 'string';
		                              description:
			                              'An optional superclass name that stops the included superclass chain at a specific ancestor. When omitted, only the requested class is inspected unless includeSuperclasses=true.';
		                              yourself.
	subclassDepthProperty := MCPStructureProperties new
		                         name: 'subclassDepth';
		                         type: 'integer';
		                         description:
			                         'How many subclass levels to include. Uses 0 by default, 1 for direct subclasses, 2 for grandchildren too, and so on.';
		                         default: 0;
		                         yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'className';
					   type: 'string';
					   description: 'The class to inspect.';
					   yourself).
				  includeSuperclassesProperty.
				  includeCommentProperty.
				  upToSuperclassNameProperty.
				  subclassDepthProperty };
		  required: #( 'className' );
		  yourself
]

{ #category : 'defaults' }
MCPToolInspectClass >> defaultName [

	^ 'inspect-class'
]

{ #category : 'defaults' }
MCPToolInspectClass >> defaultOutputSchema [

	^ self
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
						                  'The included subclasses or descendants of the inspected class, bounded by subclassDepth.')
					                 items: self classDescriptionObjectSchema;
					                 yourself) }
		                required:
		                self classDescriptionRequiredFields
		                , #( 'superclasses' 'subclasses' )
]

{ #category : 'defaults' }
MCPToolInspectClass >> defaultTitle [

	^ 'Inspect Pharo Class'
]

{ #category : 'private - hierarchy' }
MCPToolInspectClass >> descriptionDictionariesForClasses: someClasses [

	^ self
		  descriptionDictionariesForClasses: someClasses
		  includeComment: false
]

{ #category : 'private - hierarchy' }
MCPToolInspectClass >> descriptionDictionariesForClasses: someClasses includeComment: includeComment [

	^ (someClasses collect: [ :each |
		   self
			   descriptionDictionaryForClass: each
			   includeComment: includeComment ]) asArray
]

{ #category : 'private - hierarchy' }
MCPToolInspectClass >> descriptionDictionaryForClass: aClass includeComment: includeComment [

	| data |
	data := (MCPClassDescription fromClass: aClass) asDictionary copy.
	includeComment ifTrue: [
		data at: #classComment put: (aClass comment ifNil: [ '' ]) ].
	^ data
]

{ #category : 'private' }
MCPToolInspectClass >> errorResultForError: anError className: className [

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
MCPToolInspectClass >> executeWithArguments: arguments [

	| className data includeComment subclasses superclasses targetClass |
	className := self classNameFromArguments: arguments.
	^ [
	  targetClass := self resolvedClassNamed: className.
	  includeComment := self
		                    booleanArgumentNamed: 'includeComment'
		                    in: arguments
		                    default: false.
	  superclasses := self
		                  superclassesForClass: targetClass
		                  arguments: arguments.
	  subclasses := self
		                subclassesForClass: targetClass
		                arguments: arguments.
	  data := self
		          descriptionDictionaryForClass: targetClass
		          includeComment: includeComment.
	  data at: #superclasses put: (self
			   descriptionDictionariesForClasses: superclasses
			   includeComment: includeComment).
	  data at: #subclasses put: (self
			   descriptionDictionariesForClasses: subclasses
			   includeComment: includeComment).
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
MCPToolInspectClass >> failureMessageForClassName: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to inspect class ';
			  nextPutAll: className;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - hierarchy' }
MCPToolInspectClass >> resolvedClassNamed: className [

	^ Smalltalk globals
		  at: className asSymbol
		  ifAbsent: [ MCPCommandError signalMissingClassNamed: className ]
]

{ #category : 'private - hierarchy' }
MCPToolInspectClass >> sortedClassesByName: someClasses [

	^ (someClasses asSortedCollection: [ :left :right |
		   left name <= right name ]) asArray
]

{ #category : 'private - hierarchy' }
MCPToolInspectClass >> subclassesForClass: aClass arguments: arguments [

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
MCPToolInspectClass >> successSummaryForClassName: className superclasses: superclasses subclasses: subclasses [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Inspected class ';
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
MCPToolInspectClass >> superclassesForClass: aClass arguments: arguments [

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
