"
Abstract base for MCP tools exposed by the server.

A tool owns its public MCP metadata: name, title, description, icons, input schema, and output schema. The server uses that metadata when advertising tools and when validating an incoming tool call.

The normal execution flow is:
1. The MCP server receives a JSON-RPC tool call and dispatches it to the matching MCPTool instance.
2. MCPToolRequest validates the raw arguments against the tool input schema. This is the transport/schema boundary.
3. The concrete tool parses the MCPToolRequest into a tool-specific request or spec object.
4. The tool creates and dispatches a command or query command.
5. Commands perform the image operation or query and return result DTOs, info DTOs, reports, warnings, or errors.
6. The tool arranges those DTOs into text and structured output that matches its output schema.
7. The server serializes the tool result into the HTTP/JSON-RPC response.

Subclasses should keep protocol and schema mechanics in the tool, put image work in commands or query objects, and avoid passing raw argument dictionaries beyond request parsing.
"
Class {
	#name : 'MCPTool',
	#superclass : 'Object',
	#instVars : [
		'inputSchema',
		'outputSchema'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'querying' }
MCPTool class >> concreteSubclasses [

	^ self allSubclasses reject: [ :each | each isAbstract ]
]

{ #category : 'testing' }
MCPTool class >> isAbstract [

	^ self = MCPTool
]

{ #category : 'metadata' }
MCPTool class >> isBuiltIn [

	^ self package = MCPTool package
]

{ #category : 'instance creation' }
MCPTool class >> newForRegistry: aToolRegistry [

	^ self new
]

{ #category : 'scripts' }
MCPTool class >> toolGroups [

	^ MCPToolRegistry new publicToolGroups
]

{ #category : 'scripts' }
MCPTool class >> toolIconFormOf: aToolClass [

	^ Form fromBase64String:
		  (aToolClass toolIcons first src copyAfter: $,)
]

{ #category : 'icons' }
MCPTool class >> toolIconSpec [

	^ MCPToolIconSpec forToolName: self toolName
]

{ #category : 'icons' }
MCPTool class >> toolIcons [

	^ MCPStructureIcon iconsForToolClass: self
]

{ #category : 'metadata' }
MCPTool class >> toolName [

	self subclassResponsibility
]

{ #category : 'metadata' }
MCPTool >> activationRequirements [

	^ #(  )
]

{ #category : 'metadata' }
MCPTool >> additionalKeywords [

	^ #(  )
]

{ #category : 'accessing' }
MCPTool >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self description ifNotNil: [
		dic at: #description put: self description asJRPCJSON ].
	self inputSchema ifNotNil: [
		dic at: #inputSchema put: self inputSchema asJRPCJSON ].
	self name ifNotNil: [ dic at: #name put: self name asJRPCJSON ].
	self title ifNotNil: [ dic at: #title put: self title asJRPCJSON ].
	^ dic
]

{ #category : 'private - schema' }
MCPTool >> booleanSchemaPropertyNamed: propertyName description: propertyDescription [

	^ self
		  schemaPropertyNamed: propertyName
		  type: 'boolean'
		  description: propertyDescription
]

{ #category : 'private - schema' }
MCPTool >> booleanSchemaPropertyNamed: propertyName description: propertyDescription default: defaultValue [

	^ (self
		   booleanSchemaPropertyNamed: propertyName
		   description: propertyDescription)
		  default: defaultValue;
		  yourself
]

{ #category : 'metadata' }
MCPTool >> buildInputSchema [

	self subclassResponsibility
]

{ #category : 'metadata' }
MCPTool >> buildOutputSchema [

	self subclassResponsibility
]

{ #category : 'private - execution' }
MCPTool >> commandForRequest: aToolRequest [

	self subclassResponsibility
]

{ #category : 'metadata' }
MCPTool >> contractIncludingOutputSchema: includeOutputSchema [

	| activationRequirements data examples |
	data := self metadata copy.
	data at: #inputSchema put: self inputSchema asJRPCJSON.
	includeOutputSchema ifTrue: [ data at: #outputSchema put: self outputSchema asJRPCJSON ].
	examples := self examples.
	examples ifNotEmpty: [ data at: #examples put: examples ].
	activationRequirements := self activationRequirements.
	activationRequirements ifNotEmpty: [ data at: #activationRequirements put: activationRequirements ].
	^ data
]

{ #category : 'metadata' }
MCPTool >> defaultExposure [

	^ 'discoverable'
]

{ #category : 'metadata' }
MCPTool >> description [

	self subclassResponsibility
]

{ #category : 'private - results' }
MCPTool >> errorDetailsFor: anError [

	| context descriptionText details errorClassName message stackTrace |
	details := Dictionary new.
	errorClassName := anError class name asString.
	message := anError messageText
		           ifNil: [ '' ]
		           ifNotNil: [ :text | text asString ].
	details at: #errorClass put: errorClassName.
	details at: #message put: message.
	descriptionText := anError description.
	(descriptionText ~= errorClassName and: [ descriptionText ~= message ])
		ifTrue: [ details at: #description put: descriptionText ].
	context := anError mcpSignalerContext.
	context ifNotNil: [
			details at: #signalerContext put: context printString.
			stackTrace := self errorStackTraceForContext: context.
			stackTrace ifNotEmpty: [ details at: #stackTrace put: stackTrace ] ].
	^ details
]

{ #category : 'error handling' }
MCPTool >> errorResultFor: anError [

	| details |
	details := self errorDetailsFor: anError.
	anError mcpAddToolErrorDetailsTo: details.
	^ self
		  errorResultText: (self failureMessageFor: anError)
		  details: details
]

{ #category : 'error handling' }
MCPTool >> errorResultText: aString details: aDictionary [

	| details normalizedSummary structuredContent |
	normalizedSummary := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	details := aDictionary ifNil: [ Dictionary new ] ifNotNil: [ aDictionary copy ].
	details at: #message ifAbsentPut: [ normalizedSummary ].
	details at: #errorClass ifAbsentPut: [ 'ToolError' ].
	structuredContent := Dictionary new
		                     at: #status put: 'error';
		                     at: #summary put: normalizedSummary;
		                     at: #error put: details;
		                     yourself.
	^ MCPStructureErrorToolResult content: { (self textContent: normalizedSummary) } structuredContent: structuredContent
]

{ #category : 'private - schema' }
MCPTool >> errorSchemaProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'errorClass'
			   type: 'string'
			   description:
			   'The Smalltalk exception class name describing the failure.').
		  (self
			   schemaPropertyNamed: 'errorCode'
			   type: 'string'
			   description:
			   'A tool-specific error code when the failure was signaled intentionally by the MCP implementation.').
		  (self
			   schemaPropertyNamed: 'message'
			   type: 'string'
			   description: 'A concise error message describing the failure.').
		  (self
			   schemaPropertyNamed: 'description'
			   type: 'string'
			   description:
			   'A longer textual description of the failure when available.').
		  (self
			   schemaPropertyNamed: 'signalerContext'
			   type: 'string'
			   description:
			   'The signaler context recorded for the exception when available.').
		  (self
			   stringArraySchemaNamed: 'stackTrace'
			   description:
			   'A debug stack trace captured from the signaler context when available.'
			   itemDescription:
			   'One stack frame from the captured signaler chain, ordered from the signaling frame outward.') }
]

{ #category : 'private - results' }
MCPTool >> errorStackTraceForContext: aContext [

	^ ((aContext stackOfSize: self errorStackTraceLimit) collect: [ :each |
		   each printString ]) asArray
]

{ #category : 'private - results' }
MCPTool >> errorStackTraceLimit [

	^ 20
]

{ #category : 'metadata' }
MCPTool >> examples [

	^ #(  )
]

{ #category : 'private - execution' }
MCPTool >> executeParsedRequestFrom: request do: executionBlock onError: errorBlock [
	"Parse the transport request inside the same exception boundary as execution.
	The error block receives the error and the parsed request, or nil if parsing failed."

	| parsedRequest |
	^ [
		  parsedRequest := self parsedRequestFromToolRequest: request.
		  executionBlock value: parsedRequest ]
		  on: Exception
		  do: [ :error | errorBlock value: error value: parsedRequest ]
]

{ #category : 'executing' }
MCPTool >> executeWithRequest: aRequest [

	self subclassResponsibility
]

{ #category : 'error handling' }
MCPTool >> failureMessageFor: anError [

	| message |
	message := anError messageText
		           ifNil: [ '' ]
		           ifNotNil: [ :text | text asString ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Tool ';
				  nextPutAll: self name;
				  nextPutAll: ' failed (';
				  nextPutAll: anError class name;
				  nextPutAll: ')'.
			  message isEmpty ifFalse: [
					  stream
						  nextPutAll: ': ';
						  nextPutAll: message ] ]
]

{ #category : 'metadata' }
MCPTool >> groupName [

	^ 'other'
]

{ #category : 'metadata' }
MCPTool >> icons [

	^ self class toolIcons
]

{ #category : 'metadata' }
MCPTool >> inputSchema [

	^ self buildInputSchema
]

{ #category : 'private - schema' }
MCPTool >> integerSchemaPropertyNamed: propertyName description: propertyDescription [

	^ self
		  schemaPropertyNamed: propertyName
		  type: 'integer'
		  description: propertyDescription
]

{ #category : 'private - schema' }
MCPTool >> integerSchemaPropertyNamed: propertyName description: propertyDescription default: defaultValue [

	^ (self
		   integerSchemaPropertyNamed: propertyName
		   description: propertyDescription)
		  default: defaultValue;
		  yourself
]

{ #category : 'metadata' }
MCPTool >> keywords [

	| keywords normalizedKeywords |
	keywords := OrderedCollection new.
	keywords addAll: (self name findTokens: '-_').
	keywords addAll: (self title findTokens: ' -').
	keywords addAll: (self groupName findTokens: '-_').
	keywords addAll: self additionalKeywords.
	normalizedKeywords := OrderedCollection new.
	keywords do: [ :each | normalizedKeywords addAll: (each asString findTokens: '-_ ') ].
	^ (normalizedKeywords collect: [ :each | each asLowercase ]) asSet asArray
]

{ #category : 'metadata' }
MCPTool >> metadata [

	^ {
		  (#name -> self name).
		  (#description -> self description).
		  (#group -> self groupName).
		  (#mutability -> self mutability).
		  (#keywords -> self keywords) } asDictionary
]

{ #category : 'metadata' }
MCPTool >> mutability [

	^ 'write'
]

{ #category : 'metadata' }
MCPTool >> name [

	^ self class toolName
]

{ #category : 'metadata' }
MCPTool >> outputSchema [

	^ self buildOutputSchema
]

{ #category : 'private - request' }
MCPTool >> parsedRequestFromToolRequest: request [

	^ request
]

{ #category : 'private - icons' }
MCPTool >> pngCompositeBaseIconNamed: aBaseIconSymbol badgeIconNamed: aBadgeIconSymbol [

	^ MCPStructureIcon
		  compositeBaseIconNamed: aBaseIconSymbol
		  badgeIconNamed: aBadgeIconSymbol
]

{ #category : 'private - icons' }
MCPTool >> pngDataUriForForm: aForm [

	^ MCPStructureIcon pngDataUriForForm: aForm
]

{ #category : 'private - icons' }
MCPTool >> pngIconNamed: anIconSymbol [

	^ MCPStructureIcon pngIconNamed: anIconSymbol
]

{ #category : 'private - icons' }
MCPTool >> pngSizeStringForForm: aForm [

	^ aForm width asString , 'x' , aForm height asString
]

{ #category : 'validating' }
MCPTool >> requestFromToolCallArguments: toolCallArguments [

	^ MCPToolRequest tool: self arguments: toolCallArguments
]

{ #category : 'private - schema' }
MCPTool >> schemaPropertyNamed: aName type: aType description: aDescription [

	^ MCPStructureProperties new
		  name: aName;
		  type: aType;
		  description: aDescription;
		  yourself
]

{ #category : 'metadata' }
MCPTool >> searchMetadata [

	^ {
		  (#name -> self name).
		  (#description -> self description) } asDictionary
]

{ #category : 'metadata' }
MCPTool >> searchableText [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: self name;
				  space;
				  nextPutAll: self title;
				  space;
				  nextPutAll: self description;
				  space;
				  nextPutAll: self groupName.
			  self keywords do: [ :keyword |
					  stream
						  space;
						  nextPutAll: keyword ] ]
]

{ #category : 'private - schema' }
MCPTool >> shouldAdvertiseStringArrayItemDescription: anItemDescription [

	| itemDescriptionString |
	itemDescriptionString := anItemDescription
		                         ifNil: [ ^ false ]
		                         ifNotNil: [ :value |
		                         value asString trimBoth ].
	itemDescriptionString isEmpty ifTrue: [ ^ false ].
	(itemDescriptionString endsWith: ' name.') ifTrue: [ ^ false ].
	(#( 'Hierarchy root class.' ) includes: itemDescriptionString)
		ifTrue: [ ^ false ].
	^ true
]

{ #category : 'testing' }
MCPTool >> shouldSaveImageAfterSuccessfulExecution [

	^ false
]

{ #category : 'testing' }
MCPTool >> shouldSaveImageAfterSuccessfulExecutionForResult: aResult [

	^ self shouldSaveImageAfterSuccessfulExecution
]

{ #category : 'private - schema' }
MCPTool >> standardOutputSchemaForDataProperties: dataProperties required: requiredFields [

	| dataProperty errorProperty statusProperty summaryProperty |
	dataProperty := self
		                schemaPropertyNamed: 'data'
		                type: 'object'
		                description: 'Structured success payload.'.
	dataProperty
		properties: dataProperties;
		required: requiredFields;
		additionalProperties: false.
	errorProperty := self
		                 schemaPropertyNamed: 'error'
		                 type: 'object'
		                 description: 'Structured error information.'.
	errorProperty
		properties: self errorSchemaProperties;
		required: #( 'message' );
		additionalProperties: true.
	statusProperty := self
		                  stringEnumSchemaPropertyNamed: 'status'
		                  description: 'Tool result status.'
		                  values: #( 'ok' 'error' ).
	summaryProperty := self
		                   schemaPropertyNamed: 'summary'
		                   type: 'string'
		                   description: 'Human-readable result summary.'.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  statusProperty.
				  summaryProperty.
				  self warningsSchemaProperty.
				  dataProperty.
				  errorProperty };
		  required: #( 'status' 'summary' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPTool >> stringArraySchemaNamed: aName [

	^ self
		  stringArraySchemaNamed: aName
		  description: nil
		  itemDescription: nil
]

{ #category : 'private - schema' }
MCPTool >> stringArraySchemaNamed: aName description: aDescription itemDescription: anItemDescription [

	| itemsProperty |
	itemsProperty := MCPStructureProperties new
		                 type: 'string';
		                 yourself.
	(self shouldAdvertiseStringArrayItemDescription: anItemDescription)
		ifTrue: [ itemsProperty description: anItemDescription ].
	^ (self
		   schemaPropertyNamed: aName
		   type: 'array'
		   description: aDescription)
		  items: itemsProperty;
		  yourself
]

{ #category : 'private - schema' }
MCPTool >> stringEnumArraySchemaNamed: propertyName description: propertyDescription itemDescription: itemDescription values: enumValues [

	| itemsProperty |
	itemsProperty := MCPStructureProperties new
		                 type: 'string';
		                 description: itemDescription;
		                 enum: enumValues;
		                 yourself.
	^ (self
		   schemaPropertyNamed: propertyName
		   type: 'array'
		   description: propertyDescription)
		  items: itemsProperty;
		  yourself
]

{ #category : 'private - schema' }
MCPTool >> stringEnumArraySchemaNamed: propertyName description: propertyDescription itemDescription: itemDescription values: enumValues default: defaultValues [

	^ (self
		   stringEnumArraySchemaNamed: propertyName
		   description: propertyDescription
		   itemDescription: itemDescription
		   values: enumValues)
		  default: defaultValues;
		  yourself
]

{ #category : 'private - schema' }
MCPTool >> stringEnumSchemaPropertyNamed: propertyName description: propertyDescription values: enumValues [

	^ (self
		   schemaPropertyNamed: propertyName
		   type: 'string'
		   description: propertyDescription)
		  enum: enumValues;
		  yourself
]

{ #category : 'private - schema' }
MCPTool >> stringEnumSchemaPropertyNamed: propertyName description: propertyDescription values: enumValues default: defaultValue [

	^ (self
		   stringEnumSchemaPropertyNamed: propertyName
		   description: propertyDescription
		   values: enumValues)
		  default: defaultValue;
		  yourself
]

{ #category : 'private - results' }
MCPTool >> successResultText: aSummary data: aDictionary [

	^ self successResultText: aSummary data: aDictionary warnings: #(  )
]

{ #category : 'private - results' }
MCPTool >> successResultText: aSummary data: aDictionary warnings: warningStrings [

	| normalizedSummary structuredContent warnings |
	normalizedSummary := aSummary ifNil: [ '' ] ifNotNil: [ aSummary asString ].
	warnings := warningStrings ifNil: [ #(  ) ] ifNotNil: [ (warningStrings collect: [ :each | each asString ]) asArray ].
	structuredContent := Dictionary new
		                     at: #status put: 'ok';
		                     at: #summary put: normalizedSummary;
		                     at: #data put: aDictionary;
		                     yourself.
	warnings ifNotEmpty: [ structuredContent at: #warnings put: warnings ].
	^ MCPStructureCallToolResult content: { (self textContent: normalizedSummary) } structuredContent: structuredContent
]

{ #category : 'private' }
MCPTool >> successfulStructuredDataFromResult: aResult ifAbsent: absentBlock [

	| structuredContent |
	aResult isError ifTrue: [ ^ absentBlock value ].
	structuredContent := aResult structuredContent.
	structuredContent ifNil: [ ^ absentBlock value ].
	^ structuredContent at: #data ifAbsent: absentBlock
]

{ #category : 'private - results' }
MCPTool >> textContent: aString [

	^ MCPStructureTextContent text: aString
]

{ #category : 'metadata' }
MCPTool >> title [

	self subclassResponsibility
]

{ #category : 'validating' }
MCPTool >> validateRequest: aToolRequest [

	^ self
]

{ #category : 'private - schema' }
MCPTool >> warningsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'warnings'
		  description: 'Warnings produced by the tool.'
		  itemDescription: 'Warning message.'
]
