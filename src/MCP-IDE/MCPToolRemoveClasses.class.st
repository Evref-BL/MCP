"
Removes classes from the image in one batch. It surfaces safe-removal warnings before destructive changes unless forced.
"
Class {
	#name : 'MCPToolRemoveClasses',
	#superclass : 'MCPTool',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
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

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  ((MCPStructureProperties new
					    name: 'name';
					    type: #( 'string' 'array' );
					    description: 'Class name, or several removed together so references between them do not block it.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    yourself);
					   yourself).
				  (MCPStructureProperties new
					   name: 'force';
					   type: 'boolean';
					   description: 'Remove despite warnings, which are reported either way.';
					   default: false;
					   yourself) };
		  required: #( 'name' );
		  yourself
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

{ #category : 'private' }
MCPToolRemoveClasses >> errorResultForError: anError classNames: classNames [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self errorResultText: (self failureMessageForClassNames: classNames error: toolError) details: {
						  (#errorClass -> toolError class name).
						  (#message -> toolError messageText).
						  (#classes -> classNames asArray) } asDictionary ]
]

{ #category : 'executing' }
MCPToolRemoveClasses >> executeWithRequest: request [
	"The names are checked, then the classes removed. An error echoes the names each once, even one the check raises: the only check that raises no command error fails when there is no name at all."

	^ self
		  executeRequest: request
		  do: [ :arguments |
				  self checkArguments: arguments.
				  self removeClassesWith: arguments ]
		  onError: [ :error :arguments | self errorResultForError: error classNames: (self classNamesFrom: arguments) ]
]

{ #category : 'private' }
MCPToolRemoveClasses >> failureMessageForClassNames: classNames error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to remove classes: ';
				  nextPutAll: (', ' join: classNames);
				  nextPutAll: ' (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: anError messageText ]
]

{ #category : 'private - results' }
MCPToolRemoveClasses >> keysStatedInSummary [
	"The summary already reads 'Removed class Foo. Reparented subclasses: Baz. Removed packages: Bar.'"

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
MCPToolRemoveClasses >> successSummaryForClassNames: classNames removal: aRemoval [
	"Each subclass moved up is named once. A removal that warned went past what blocked it."

	| reparentedSubclassNames |
	reparentedSubclassNames := OrderedCollection new.
	aRemoval reparentedSubclassNames do: [ :each |
		(reparentedSubclassNames includes: each) ifFalse: [ reparentedSubclassNames add: each ] ].
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
			  reparentedSubclassNames ifNotEmpty: [
					  stream
						  nextPutAll: ' Reparented subclasses: ';
						  nextPutAll: (', ' join: reparentedSubclassNames);
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
