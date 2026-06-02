"
Common behavior for tools that load Metacello baselines.
"
Class {
	#name : 'MCPToolLoadMetacello',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolLoadMetacello class >> isAbstract [

	^ self = MCPToolLoadMetacello
]

{ #category : 'private - execution' }
MCPToolLoadMetacello >> commandForRequest: loadRequest [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPToolLoadMetacello >> defaultOnConflict [

	^ 'useLoaded'
]

{ #category : 'defaults' }
MCPToolLoadMetacello >> defaultOnWarning [

	^ 'log'
]

{ #category : 'private - errors' }
MCPToolLoadMetacello >> errorDetailsForError: anError loadRequest: loadRequest rawRequest: rawRequest [

	| context details |
	details := anError
		           mcpCommandErrorDo: [ :commandError |
		           commandError structuredDetails copy ]
		           otherwise: [ self errorDetailsFor: anError ].
	context := self
		           requestedContextForErrorFromLoadRequest: loadRequest
		           rawRequest: rawRequest.
	context keysAndValuesDo: [ :key :value |
		value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ].
	^ details
]

{ #category : 'private - errors' }
MCPToolLoadMetacello >> errorResultForError: anError loadRequest: loadRequest rawRequest: rawRequest [

	^ self
		  errorResultText: (self
				   failureSummaryForError: anError
				   loadRequest: loadRequest
				   rawRequest: rawRequest)
		  details: (self
				   errorDetailsForError: anError
				   loadRequest: loadRequest
				   rawRequest: rawRequest)
]

{ #category : 'executing' }
MCPToolLoadMetacello >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :loadRequest |
				  | result |
				  result := (self commandForRequest: loadRequest) execute.
				  self
					  successResultText: (self successSummaryForResult: result)
					  data: result asDictionary ]
		  onError: [ :error :loadRequest |
				  self
					  errorResultForError: error
					  loadRequest: loadRequest
					  rawRequest: request ]
]

{ #category : 'private - errors' }
MCPToolLoadMetacello >> failureSummaryForError: anError loadRequest: loadRequest rawRequest: rawRequest [

	| baseline message |
	message := anError messageText
		           ifNil: [ anError asString ]
		           ifNotNil: [ :text | text asString ].
	loadRequest ifNil: [ ^ 'Failed to load baseline: ' , message ].
	baseline := loadRequest baseline ifNil: [ '' ].
	^ String streamContents: [ :stream |
			  stream nextPutAll: 'Failed to load baseline'.
			  baseline isEmpty ifFalse: [
					  stream
						  space;
						  nextPutAll: baseline ].
			  stream
				  nextPutAll: ': ';
				  nextPutAll: message ]
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> groupsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'groups'
		  description:
		  'Optional Metacello load groups. Omit or pass an empty array to call Metacello>>load.'
		  itemDescription: 'A Metacello group name.'
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> loadBaselineDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'baseline'
			   type: 'string'
			   description: 'The Metacello baseline name requested.').
		  (self
			   stringArraySchemaNamed: 'groups'
			   description: 'Metacello load groups requested.'
			   itemDescription: 'A Metacello group name.').
		  (self
			   schemaPropertyNamed: 'onWarning'
			   type: 'string'
			   description: 'The warning policy used.').
		  (self
			   schemaPropertyNamed: 'onConflict'
			   type: 'string'
			   description: 'The conflict policy used.').
		  (self
			   stringArraySchemaNamed: 'newPackageNames'
			   description:
			   'Packages that appeared in the image after the load and were not present before it started.'
			   itemDescription: 'A package name.').
		  self repositoriesOutputSchemaProperty }
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> loadBaselineOutputSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'load'
		   type: 'object'
		   description: 'Baseline load details for the Metacello load.')
		  properties: self loadBaselineDataProperties;
		  required:
			  #( 'baseline' 'groups' 'onWarning' 'onConflict' 'newPackageNames'
			     'repositories' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> nonEmptyStringSchemaPropertyNamed: propertyName description: propertyDescription [

	^ (self
		   schemaPropertyNamed: propertyName
		   type: 'string'
		   description: propertyDescription)
		  minLength: 1;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onConflictSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'onConflict'
		  description:
		  'Metacello project conflict handling policy. useLoaded keeps the loaded registration, useIncoming accepts the incoming registration, and pass leaves Metacello default conflict handling.'
		  values: #( 'useLoaded' 'useIncoming' 'pass' )
		  default: self defaultOnConflict
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onWarningSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'onWarning'
		  description:
		  'Metacello warning handling policy. log records and resumes warnings, resume resumes without logging, and pass leaves Metacello default warning handling.'
		  values: #( 'log' 'resume' 'pass' )
		  default: self defaultOnWarning
]

{ #category : 'private - request' }
MCPToolLoadMetacello >> parsedRequestFromToolRequest: request [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> repositoriesOutputSchemaProperty [

	| property |
	property := self
		            schemaPropertyNamed: 'repositories'
		            type: 'array'
		            description:
		            'Iceberg repositories newly registered during the load, when detectable.'.
	property items: self repositoryInfoOutputSchemaProperty.
	^ property
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> repositoryInfoOutputSchemaProperty [

	^ MCPStructureProperties new
		  type: 'object';
		  description:
			  'Structured metadata for one Iceberg repository newly registered during the load.';
		  additionalProperties: true;
		  yourself
]

{ #category : 'private - errors' }
MCPToolLoadMetacello >> requestedContextForErrorFromLoadRequest: loadRequest rawRequest: rawRequest [

	loadRequest ifNotNil: [ ^ loadRequest requestedContext ].
	^ rawRequest asDictionary copy
]

{ #category : 'private - results' }
MCPToolLoadMetacello >> successSummaryForResult: aResult [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Loaded baseline ';
				  nextPutAll: aResult baseline;
				  nextPut: $..
			  aResult newPackageNames isEmpty ifFalse: [
					  stream
						  space;
						  nextPutAll: aResult newPackageNames size asString;
						  nextPutAll: ' new packages were detected.' ] ]
]
