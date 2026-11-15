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

{ #category : 'private - errors' }
MCPToolRemoveClasses >> classNamesForErrorFromParsedRequest: removeRequest rawRequest: rawRequest [

	removeRequest ifNotNil: [ ^ removeRequest classNames ].
	^ rawRequest stringCollectionArgumentNamed: 'name'
]

{ #category : 'private' }
MCPToolRemoveClasses >> classNamesFromRequest: request [
	"One class side among the names refuses the whole call, before anything is looked up: read as its class, it would delete the class."

	| classNames |
	classNames := request uniqueStringCollectionArgumentNamed: 'name'.
	classNames ifEmpty: [ Error signal: 'name must hold at least one class name.' ].
	^ classNames collect: [ :each | MCPImageLookup wholeClassName: each for: 'class_remove' ]
]

{ #category : 'private - execution' }
MCPToolRemoveClasses >> commandForRequest: removeRequest [

	^ MCPRemoveClassesCommand classNames: removeRequest classNames force: removeRequest force
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

{ #category : 'private - results' }
MCPToolRemoveClasses >> errorTextOn: stream for: error [
	"A refusal's summary counts the methods that refer to each class; the lines after it name them, the first five of each."

	super errorTextOn: stream for: error.
	error
		at: #referencedBy
		ifPresent: [ :references | self referencedByTextOn: stream for: references classNames: (error at: #classes) ]
]

{ #category : 'executing' }
MCPToolRemoveClasses >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :removeRequest |
				  | result |
				  result := (self commandForRequest: removeRequest) execute.
				  self
					  successResultText: (self
							   successSummaryForClassNames: removeRequest classNames
							   removedClasses: result removedClasses
							   removedPackageNames: result removedPackageNames
							   forced: result warningMessages isNotEmpty)
					  data: result asDictionary
					  warnings: result warningMessages ]
		  onError: [ :error :removeRequest |
			  self errorResultForError: error classNames: (self classNamesForErrorFromParsedRequest: removeRequest rawRequest: request) ]
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

{ #category : 'private - request' }
MCPToolRemoveClasses >> parsedRequestFromToolRequest: request [

	^ MCPRemoveClassesRequest fromRequest: request tool: self
]

{ #category : 'private - results' }
MCPToolRemoveClasses >> referencedByTextOn: stream for: references classNames: classNames [
	"One class's methods follow the label; several classes get a line each, in the order they were asked for."

	stream
		nextPut: Character lf;
		nextPutAll: 'referencedBy:'.
	classNames size = 1 ifTrue: [
			^ stream
				  space;
				  nextPutAll: (self shortenedReferenceList: (references at: classNames first)) ].
	classNames do: [ :each |
			references at: each ifPresent: [ :methods |
					stream
						nextPut: Character lf;
						nextPutAll: '  ';
						nextPutAll: each;
						nextPutAll: ': ';
						nextPutAll: (self shortenedReferenceList: methods) ] ]
]

{ #category : 'private - results' }
MCPToolRemoveClasses >> shortenedReferenceList: someMethods [
	"The first five methods; method_reference_search lists every one."

	^ String streamContents: [ :stream |
			  stream nextPutAll: (', ' join: (someMethods first: (someMethods size min: 5))).
			  someMethods size > 5 ifTrue: [
					  stream
						  nextPutAll: ', and ';
						  print: someMethods size - 5;
						  nextPutAll: ' more (method_reference_search lists them)' ] ]
]

{ #category : 'private' }
MCPToolRemoveClasses >> successSummaryForClassNames: classNames removedClasses: removedClasses removedPackageNames: removedPackageNames forced: wasForced [

	| reparentedSubclassNames |
	reparentedSubclassNames := OrderedCollection new.
	removedClasses do: [ :each |
			each reparentedSubclassNames do: [ :subclassName |
				(reparentedSubclassNames includes: subclassName) ifFalse: [ reparentedSubclassNames add: subclassName ] ] ].
	^ String streamContents: [ :stream |
			  classNames size = 1
				  ifTrue: [
						  wasForced
							  ifTrue: [
									  stream
										  nextPutAll: 'Force-removed class ';
										  nextPutAll: classNames first;
										  nextPut: $. ]
							  ifFalse: [
									  stream
										  nextPutAll: 'Removed class ';
										  nextPutAll: classNames first;
										  nextPut: $. ] ]
				  ifFalse: [
						  wasForced
							  ifTrue: [
									  stream
										  nextPutAll: 'Force-removed ';
										  nextPutAll: classNames size asString;
										  nextPutAll: ' classes: ';
										  nextPutAll: (', ' join: classNames);
										  nextPut: $. ]
							  ifFalse: [
									  stream
										  nextPutAll: 'Removed ';
										  nextPutAll: classNames size asString;
										  nextPutAll: ' classes: ';
										  nextPutAll: (', ' join: classNames);
										  nextPut: $. ] ].
			  reparentedSubclassNames ifNotEmpty: [
					  stream
						  space;
						  nextPutAll: 'Reparented subclasses: ';
						  nextPutAll: (', ' join: reparentedSubclassNames);
						  nextPut: $. ].
			  removedPackageNames ifNotEmpty: [
					  stream
						  space;
						  nextPutAll: 'Removed packages: ';
						  nextPutAll: (', ' join: removedPackageNames);
						  nextPut: $. ] ]
]

{ #category : 'metadata' }
MCPToolRemoveClasses >> title [

	^ 'Remove Classes'
]
