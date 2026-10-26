"
Returns structured metadata for one class, with optional superclass and subclass context. It is meant for single-class lookup rather than broad search.
"
Class {
	#name : 'MCPToolGetClass',
	#superclass : 'MCPTool',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
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
		                              description:
			                              'Return the superclass hierarchy up to and not including the given class. Using Object returns the whole superclass hierarchy.';
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
				                 description: 'A class name.';
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

{ #category : 'private - errors' }
MCPToolGetClass >> classNameForErrorFromParsedRequest: getRequest rawRequest: rawRequest [

	getRequest ifNotNil: [ ^ getRequest className ].
	^ (rawRequest stringArgumentNamed: 'name') ifNil: [ '' ]
]

{ #category : 'private - request' }
MCPToolGetClass >> classNameFromRequest: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	className ifNil: [ Error signal: 'name must be a non-empty string.' ].
	^ className
]

{ #category : 'private - execution' }
MCPToolGetClass >> commandForRequest: getRequest [

	^ MCPGetClassCommand tool: self request: getRequest
]

{ #category : 'metadata' }
MCPToolGetClass >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolGetClass >> description [

	^ 'Get metadata for one or more classes or traits. Optional superclass/subclass context, and the classes using a trait. Use class_search to discover names.'
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> descriptionDictionariesForClasses: someClasses includeComment: includeComment [

	^ (someClasses collect: [ :each | self descriptionDictionaryForClass: each includeComment: includeComment ]) asArray
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> descriptionDictionaryForClass: aClass includeComment: includeComment [

	| data |
	data := (MCPClassDescriptionInfo fromClass: aClass) asDictionary copy.
	includeComment ifTrue: [ data at: #comment put: (aClass comment ifNil: [ '' ]) ].
	^ data
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

	^ self executeBatchedRequest: request do: [ :targetRequest |
			  self
				  executeParsedRequestFrom: targetRequest
				  do: [ :getRequest |
						  | commandResult |
						  commandResult := (self commandForRequest: getRequest) execute.
						  self successResultText: (self successSummaryFor: commandResult) data: commandResult data ]
				  onError: [ :error :getRequest |
					  self errorResultForError: error className: (self classNameForErrorFromParsedRequest: getRequest rawRequest: targetRequest) ] ]
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

{ #category : 'private - results' }
MCPToolGetClass >> keyOrder [
	"What a class is, then where it lives, then how big it is. The comment is not named, so it lands after the inline values like any block of text."

	^ #( superclass layout package tag classMethods methods )
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

{ #category : 'private - request' }
MCPToolGetClass >> parsedRequestFromToolRequest: request [

	^ MCPGetClassRequest fromRequest: request tool: self
]

{ #category : 'private - results' }
MCPToolGetClass >> successSummaryFor: aResult [
	"A trait is named as one. It is not a class, and it has users rather than superclasses and subclasses."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Got ';
				  nextPutAll: ((aResult data at: #isTrait ifAbsent: [ false ])
						   ifTrue: [ 'trait ' ]
						   ifFalse: [ 'class ' ]);
				  nextPutAll: aResult className;
				  nextPut: $..
			  (aResult superclasses isEmpty and: [ aResult subclasses isEmpty ]) ifFalse: [
					  stream
						  space;
						  nextPutAll: 'Included ';
						  print: aResult superclasses size;
						  nextPutAll: ' superclass';
						  nextPutAll: (aResult superclasses size = 1
								   ifTrue: [ '' ]
								   ifFalse: [ 'es' ]);
						  nextPutAll: ' and ';
						  print: aResult subclasses size;
						  nextPutAll: ' subclass';
						  nextPutAll: (aResult subclasses size = 1
								   ifTrue: [ '' ]
								   ifFalse: [ 'es' ]);
						  nextPut: $. ] ]
]

{ #category : 'metadata' }
MCPToolGetClass >> title [

	^ 'Get Class'
]
