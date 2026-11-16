"
Returns structured metadata for one class, with optional superclass and subclass context. It is meant for single-class lookup rather than broad search.
"
Class {
	#name : 'MCPToolGetClass',
	#superclass : 'MCPTool',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolGetClass class >> groupName [

	^ self classesGroupName
]

{ #category : 'metadata' }
MCPToolGetClass class >> toolName [

	^ 'class_get'
]

{ #category : 'metadata' }
MCPToolGetClass >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolGetClass >> batchArgumentName [

	^ 'name'
]

{ #category : 'metadata' }
MCPToolGetClass >> batchSummaryNoun [

	^ 'classes'
]

{ #category : 'metadata' }
MCPToolGetClass >> batchSummaryVerb [

	^ 'Got'
]

{ #category : 'metadata' }
MCPToolGetClass >> buildInputSchema [

	| includeCommentProperty subclassDepthProperty upToSuperclassNameProperty nameProperty |
	includeCommentProperty := MCPStructureProperties new
		                          name: 'includeComment';
		                          type: 'boolean';
		                          description: 'Include class comments.';
		                          default: false;
		                          yourself.
	upToSuperclassNameProperty := MCPStructureProperties new
		                              name: 'upToSuperclass';
		                              type: 'string';
		                              description: 'Also list superclasses up to, not including, this class.';
		                              yourself.
	subclassDepthProperty := MCPStructureProperties new
		                         name: 'subclassDepth';
		                         type: 'integer';
		                         description: 'Return subclasses down to the given level.';
		                         default: 0;
		                         minimum: 0;
		                         maximum: self maximumSubclassDepth;
		                         yourself.
	nameProperty := MCPStructureProperties new
		                name: 'name';
		                type: #( 'string' 'array' );
		                description: 'Class name, or several class names.';
		                items: (MCPStructureProperties new
				                 type: 'string';
				                 yourself);
		                yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  nameProperty.
				  includeCommentProperty.
				  upToSuperclassNameProperty.
				  subclassDepthProperty };
		  required: #( 'name' );
		  yourself
]

{ #category : 'private - request' }
MCPToolGetClass >> classNameFromRequest: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	className ifNil: [ Error signal: 'name must be a non-empty string.' ].
	^ className
]

{ #category : 'metadata' }
MCPToolGetClass >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolGetClass >> description [

	^ 'Get class or trait definitions by name: superclass, slots, traits, package. method_search lists their methods.'
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> descriptionDictionariesForClasses: someClasses includeComment: includeComment [

	^ someClasses collect: [ :each | self descriptionDictionaryForClass: each includeComment: includeComment ] as: Array
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> descriptionDictionaryForClass: aClass includeComment: includeComment [

	| data |
	data := (MCPClassDescriptionInfo fromClass: aClass) asDictionary copy.
	includeComment ifTrue: [ data at: #comment put: (aClass comment ifNil: [ '' ]) ].
	^ data
]

{ #category : 'private - results' }
MCPToolGetClass >> entryNameKeys [
	"A superclass or subclass record is a class."

	^ #( class )
]

{ #category : 'private' }
MCPToolGetClass >> errorResultForError: anError className: className [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self errorResultText: (self failureMessageForClassName: className error: toolError) details: {
						  (#errorClass -> toolError class name).
						  (#message -> toolError messageText).
						  (#class -> className) } asDictionary ]
]

{ #category : 'executing' }
MCPToolGetClass >> executeWithRequest: request [
	"An error names the class as the name argument gives it, the same name before and after it is checked."

	^ self executeBatchedRequest: request do: [ :targetRequest |
			  self
				  executeParsedRequestFrom: targetRequest
				  do: [ :arguments | self getClassWith: arguments ]
				  onError: [ :error :arguments |
				  self errorResultForError: error className: ((arguments stringArgumentNamed: 'name') ifNil: [ '' ]) ] ]
]

{ #category : 'private' }
MCPToolGetClass >> failureMessageForClassName: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to get class ';
				  nextPutAll: className;
				  nextPutAll: ' (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: anError messageText ]
]

{ #category : 'private - execution' }
MCPToolGetClass >> getClassWith: request [
	"The answer names the class found, not the name asked for: Foo class reads as Foo, and the summary says Foo."

	| data includeComment subclasses superclasses targetClass |
	targetClass := self resolvedClassNamed: (self classNameFromRequest: request).
	superclasses := self superclassesOf: targetClass upTo: (request stringArgumentNamed: 'upToSuperclass').
	subclasses := self subclassesOf: targetClass downTo: (request integerArgumentNamed: 'subclassDepth').
	includeComment := request booleanArgumentNamed: 'includeComment'.
	data := self descriptionDictionaryForClass: targetClass includeComment: includeComment.
	superclasses ifNotEmpty: [
		data at: #superclasses put: (self descriptionDictionariesForClasses: superclasses includeComment: includeComment) ].
	subclasses ifNotEmpty: [
		data at: #subclasses put: (self descriptionDictionariesForClasses: subclasses includeComment: includeComment) ].
	^ self successResultText: (self successSummaryForClass: targetClass superclasses: superclasses subclasses: subclasses) data: data
]

{ #category : 'private - results' }
MCPToolGetClass >> keyOrder [
	"What a class is, then where it lives, then how big it is. The comment is not named, so it lands after the inline values like any block of text."

	^ #( superclass package tag layout methods classMethods traits instanceSlots classSlots sharedVariables sharedPools users )
]

{ #category : 'private - results' }
MCPToolGetClass >> keysStatedInSummary [
	"The summary opens with the class name and says whether it is a trait, so repeating either says it twice."

	^ #( class isTrait )
]

{ #category : 'defaults' }
MCPToolGetClass >> maximumSubclassDepth [

	^ 10
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> subclassesOf: aClass downTo: aDepth [

	| subclasses |
	aDepth = 0 ifTrue: [ ^ #(  ) ].
	subclasses := OrderedCollection new.
	aClass
		allSubclassesWithLevelDo: [ :eachClass :level | (level between: 1 and: aDepth) ifTrue: [ subclasses add: eachClass ] ]
		startingLevel: 0.
	^ subclasses asArray
]

{ #category : 'private - results' }
MCPToolGetClass >> successSummaryForClass: aClass superclasses: superclasses subclasses: subclasses [
	"A trait is named as one. It is not a class, and it has users rather than superclasses and subclasses."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Got ';
				  nextPutAll: (aClass isTrait
						   ifTrue: [ 'trait ' ]
						   ifFalse: [ 'class ' ]);
				  nextPutAll: aClass name;
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
MCPToolGetClass >> superclassesOf: aClass upTo: aSuperclassName [
	"The superclasses of aClass up to, not including, the one aSuperclassName names. None when no name is given."

	| targetSuperclass |
	aSuperclassName ifNil: [ ^ #(  ) ].
	targetSuperclass := MCPImageLookup classNamed: aSuperclassName role: #superclass details: { (#class -> aClass name asString) }.
	^ aClass allSuperclasses asArray copyUpTo: targetSuperclass
]

{ #category : 'metadata' }
MCPToolGetClass >> title [

	^ 'Get Class'
]
