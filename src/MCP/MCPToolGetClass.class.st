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
MCPToolGetClass class >> toolName [

	^ 'class_get'
]

{ #category : 'metadata' }
MCPToolGetClass >> buildInputSchema [

	| includeCommentProperty subclassDepthProperty upToSuperclassNameProperty |
	includeCommentProperty := MCPStructureProperties new
		                          name: 'includeComment';
		                          type: 'boolean';
		                          description: 'Include class comments.';
		                          default: false;
		                          yourself.
	upToSuperclassNameProperty := MCPStructureProperties new
		                              name: 'upToSuperclassName';
		                              type: 'string';
		                              description:
			                              'Ancestor superclass stop.';
		                              yourself.
	subclassDepthProperty := MCPStructureProperties new
		                         name: 'subclassDepth';
		                         type: 'integer';
		                         description: 'Subclass levels.';
		                         default: 0;
		                         minimum: 0;
		                         maximum: self maximumSubclassDepth;
		                         yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'className';
					   type: 'string';
					   description: 'Class name.';
					   yourself).
				  includeCommentProperty.
				  upToSuperclassNameProperty.
				  subclassDepthProperty };
		  required: #( 'className' );
		  yourself
]

{ #category : 'metadata' }
MCPToolGetClass >> buildOutputSchema [

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
						    'The included subclasses or descendants of the requested class, bounded by subclassDepth.')
					   items: self classDescriptionObjectSchema;
					   yourself) }
		  required:
		  self classDescriptionRequiredFields
		  , #( 'superclasses' 'subclasses' )
]

{ #category : 'private - schema' }
MCPToolGetClass >> classDescriptionDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'The requested class.').
		  (self
			   schemaPropertyNamed: 'superclassName'
			   type: 'string'
			   description:
			   'The direct superclass of the requested class, or an empty string for the root.').
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
			   schemaPropertyNamed: 'traitComposition'
			   type: 'string'
			   description:
			   'The full instance-side trait composition expression, preserving aliases, exclusions, and compound compositions.').
		  (self
			   schemaPropertyNamed: 'classTraitComposition'
			   type: 'string'
			   description:
			   'The full class-side trait composition expression, preserving aliases, exclusions, and compound compositions.').
		  (self
			   stringArraySchemaNamed: 'sharedPoolNames'
			   description: 'The shared pools referenced by the class.'
			   itemDescription: 'A shared pool name.').
		  (self
			   stringArraySchemaNamed: 'sharedVariableNames'
			   description: 'The class variables defined on the class.'
			   itemDescription: 'A class variable name.').
		  (self
			   schemaPropertyNamed: 'layoutClassName'
			   type: 'string'
			   description: 'The layout class used by the class.').
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
MCPToolGetClass >> classDescriptionObjectSchema [

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
MCPToolGetClass >> classDescriptionRequiredFields [

	^ #( 'className' 'superclassName' 'packageName' 'tag' 'instanceSlotNames'
	     'classSlotNames' 'traitNames' 'classTraitNames'
	     'traitComposition' 'classTraitComposition'
	     'sharedPoolNames' 'sharedVariableNames' 'layoutClassName'
	     'instanceMethodCount' 'classMethodCount' )
]

{ #category : 'private - errors' }
MCPToolGetClass >> classNameForErrorFromParsedRequest: getRequest rawRequest: rawRequest [

	getRequest ifNotNil: [ ^ getRequest className ].
	^ (rawRequest stringArgumentNamed: 'className') ifNil: [ '' ]
]

{ #category : 'private - request' }
MCPToolGetClass >> classNameFromRequest: request [

	| className |
	className := request stringArgumentNamed: 'className'.
	className ifNil: [
		Error signal: 'className must be a non-empty string.' ].
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

	^ 'Get metadata for one class. Optional superclass/subclass context. Use class_search to discover class names.'
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> descriptionDictionariesForClasses: someClasses includeComment: includeComment [

	^ (someClasses collect: [ :each |
			   self
				   descriptionDictionaryForClass: each
				   includeComment: includeComment ]) asArray
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> descriptionDictionaryForClass: aClass includeComment: includeComment [

	| data |
	data := (MCPClassDescriptionInfo fromClass: aClass) asDictionary copy.
	includeComment ifTrue: [
		data at: #classComment put: (aClass comment ifNil: [ '' ]) ].
	^ data
]

{ #category : 'private' }
MCPToolGetClass >> errorResultForError: anError className: className [

	^ anError
		  mcpCommandErrorDo: [ :commandError |
				  self
					  errorResultText: commandError messageText
					  details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self
					  errorResultText:
					  (self failureMessageForClassName: className error: toolError)
					  details: {
							  (#errorClass -> toolError class name).
							  (#message -> toolError messageText).
							  (#className -> className) } asDictionary ]
]

{ #category : 'executing' }
MCPToolGetClass >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :getRequest |
				  | commandResult |
				  commandResult := (self commandForRequest: getRequest) execute.
				  self
					  successResultText: (self
							   successSummaryForClassName: commandResult className
							   superclasses: commandResult superclasses
							   subclasses: commandResult subclasses)
					  data: commandResult data ]
		  onError: [ :error :getRequest |
				  self errorResultForError: error className: (self
						   classNameForErrorFromParsedRequest: getRequest
						   rawRequest: request) ]
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

{ #category : 'metadata' }
MCPToolGetClass >> groupName [

	^ 'classes'
]

{ #category : 'defaults' }
MCPToolGetClass >> maximumSubclassDepth [

	^ 3
]

{ #category : 'metadata' }
MCPToolGetClass >> mutability [

	^ 'read'
]

{ #category : 'private - request' }
MCPToolGetClass >> parsedRequestFromToolRequest: request [

	^ MCPGetClassRequest fromRequest: request tool: self
]

{ #category : 'private' }
MCPToolGetClass >> successSummaryForClassName: className superclasses: superclasses subclasses: subclasses [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Got class ';
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

{ #category : 'metadata' }
MCPToolGetClass >> title [

	^ 'Get Class'
]
