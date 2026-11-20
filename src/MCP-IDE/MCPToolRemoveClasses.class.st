"
Removes classes from the image in one batch. It surfaces safe-removal warnings before destructive changes unless forced.
"
Class {
	#name : 'MCPToolRemoveClasses',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRemoveClasses class >> groupName [

	^ self classesGroupName
]

{ #category : 'metadata' }
MCPToolRemoveClasses class >> toolName [

	^ 'class_remove'
]

{ #category : 'metadata' }
MCPToolRemoveClasses >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  (self
					   stringOrArraySchemaNamed: 'name'
					   description: 'Class name, or several removed together so references between them do not block it.'
					   itemDescription: 'Class name.').
				  (self
					   booleanSchemaPropertyNamed: 'force'
					   description: 'Remove despite warnings, which are reported either way.'
					   default: false) }
		  required: #( 'name' )
]

{ #category : 'private - arguments' }
MCPToolRemoveClasses >> checkArguments: request [
	"At least one name, and none of a class side. One class side among the names refuses the whole call, before anything is looked up: read as its class, it would delete the class."

	| classNames |
	classNames := self classNamesFrom: request.
	classNames ifEmpty: [ Error signal: 'name must hold at least one class name.' ].
	classNames do: [ :each | MCPImageLookup wholeClassName: each for: 'class_remove' ]
]

{ #category : 'private - arguments' }
MCPToolRemoveClasses >> classNamesFrom: request [
	"Each name once, in the order given."

	^ request uniqueStringCollectionArgumentNamed: 'name'
]

{ #category : 'private - results' }
MCPToolRemoveClasses >> dataFor: aRemoval [
	"What the removal changed besides the classes, when it changed anything: the packages it left empty and the subclasses it moved up."

	| data |
	data := Dictionary new.
	aRemoval removedPackageNames ifNotEmpty: [ :names | data at: #removedPackageNames put: names asArray ].
	aRemoval reparentedSubclassNames ifNotEmpty: [ :names | data at: #reparentedSubclassNames put: names asArray ].
	^ data
]

{ #category : 'metadata' }
MCPToolRemoveClasses >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolRemoveClasses >> description [

	^ 'Remove classes in one change. Warnings, such as remaining references, stop it unless force is true.'
]

{ #category : 'executing' }
MCPToolRemoveClasses >> executeWithRequest: request [
	"The names are checked, then the classes removed. An error echoes the names each once, even one the check raises: the only check that raises no command error fails when there is no name at all."

	^ self
		  executeRequest: request
		  do: [
				  self checkArguments: request.
				  self removeClassesWith: request ]
		  onError: [ :error |
				  | classNames |
				  classNames := self classNamesFrom: request.
				  self
					  errorResultFor: error
					  unableTo: 'remove classes: ' , (', ' join: classNames)
					  details: { (#classes -> classNames asArray) } ]
]

{ #category : 'private - results' }
MCPToolRemoveClasses >> keysStatedInSummary [
	"The summary already reads 'Removed class Foo. Baz now inherits from Object. Removed packages: Bar.'"

	^ #( removedClasses removedPackageNames reparentedSubclassNames )
]

{ #category : 'private - execution' }
MCPToolRemoveClasses >> removeClassesWith: request [

	| classNames removal |
	classNames := self classNamesFrom: request.
	removal := MCPRemoveClassesCommand classNames: classNames force: (request booleanArgumentNamed: 'force').
	removal execute.
	^ self
		  successResultText: (self successSummaryForClassNames: classNames removal: removal)
		  data: (self dataFor: removal)
		  warnings: removal warningMessages
]

{ #category : 'private' }
MCPToolRemoveClasses >> sentenceForMethodNames: someMethodNames removedWithClasses: aCount [
	"Its 3 methods were removed with it: Foo>>a, Foo>>b and Foo class>>c. Past ten methods, only how many, since naming them all would bury the rest of the answer."

	^ String streamContents: [ :stream |
			  stream nextPutAll: (aCount = 1
					   ifTrue: [ 'Its ' ]
					   ifFalse: [ 'Their ' ]).
			  someMethodNames size = 1
				  ifTrue: [ stream << 'method ' << someMethodNames first << ' was' ]
				  ifFalse: [ stream << someMethodNames size printString << ' methods were' ].
			  stream nextPutAll: (aCount = 1
					   ifTrue: [ ' removed with it' ]
					   ifFalse: [ ' removed with them' ]).
			  (someMethodNames size between: 2 and: 10) ifTrue: [ stream << ': ' << (MCPCommandError joinedNames: someMethodNames) ].
			  stream nextPut: $. ]
]

{ #category : 'private' }
MCPToolRemoveClasses >> successSummaryForClassNames: classNames removal: aRemoval [
	"Each subclass moved up is named once, with the class it inherits from now, so that a class made again under a removed name is not taken to bring it back. The methods that went with the classes are said, since a caller removing a class may not count them gone. A removal that warned went past what blocked it."

	^ String streamContents: [ :stream |
			  stream nextPutAll: (aRemoval warningMessages ifEmpty: [ 'Removed ' ] ifNotEmpty: [ 'Force-removed ' ]).
			  classNames size = 1
				  ifTrue: [
						  stream
							  nextPutAll: 'class ';
							  nextPutAll: classNames first ]
				  ifFalse: [
						  stream
							  print: classNames size;
							  nextPutAll: ' classes: ';
							  nextPutAll: (', ' join: classNames) ].
			  stream nextPut: $..
			  aRemoval removedMethodNames ifNotEmpty: [ :names |
					  stream
						  space;
						  nextPutAll: (self sentenceForMethodNames: names removedWithClasses: classNames size) ].
			  aRemoval reparentedSubclassNamesBySuperclassName keysAndValuesDo: [ :superclassName :subclassNames |
					  stream
						  space;
						  nextPutAll: (MCPCommandError joinedNames: subclassNames);
						  nextPutAll: (subclassNames size = 1
								   ifTrue: [ ' now inherits from ' ]
								   ifFalse: [ ' now inherit from ' ]);
						  nextPutAll: superclassName;
						  nextPut: $. ].
			  aRemoval removedPackageNames ifNotEmpty: [ :names |
					  stream
						  nextPutAll: ' Removed packages: ';
						  nextPutAll: (', ' join: names);
						  nextPut: $. ] ]
]

{ #category : 'metadata' }
MCPToolRemoveClasses >> title [

	^ 'Remove Classes'
]
