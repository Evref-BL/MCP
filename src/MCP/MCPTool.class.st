"
Abstract base for MCP tools exposed by the server.

A tool owns its public MCP metadata: name, title, description, icons, annotations, input schema, and output schema. The server uses that metadata when advertising tools and when validating an incoming tool call.

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

{ #category : 'metadata - groups' }
MCPTool class >> builtInGroupNames [

	^ {
		  self classesGroupName.
		  self debuggingGroupName.
		  self historyGroupName.
		  self methodsGroupName.
		  self packagesGroupName.
		  self repositoriesGroupName.
		  self runtimeGroupName.
		  self testsGroupName.
		  self toolCatalogGroupName.
		  self uiGroupName }
]

{ #category : 'metadata - groups' }
MCPTool class >> classesGroupName [

	^ 'classes'
]

{ #category : 'querying' }
MCPTool class >> concreteSubclasses [

	^ self allSubclasses reject: [ :each | each isAbstract ]
]

{ #category : 'metadata - groups' }
MCPTool class >> debuggingGroupName [

	^ 'debugging'
]

{ #category : 'metadata' }
MCPTool class >> groupName [

	^ self otherGroupName
]

{ #category : 'metadata - groups' }
MCPTool class >> historyGroupName [

	^ 'history'
]

{ #category : 'testing' }
MCPTool class >> isAbstract [

	^ self = MCPTool
]

{ #category : 'metadata' }
MCPTool class >> isBuiltIn [

	^ self package = MCPTool package
]

{ #category : 'metadata - groups' }
MCPTool class >> methodsGroupName [

	^ 'methods'
]

{ #category : 'instance creation' }
MCPTool class >> newForRegistry: aToolRegistry [

	^ self new
]

{ #category : 'metadata - groups' }
MCPTool class >> otherGroupName [

	^ 'other'
]

{ #category : 'metadata - groups' }
MCPTool class >> packagesGroupName [

	^ 'packages'
]

{ #category : 'metadata - groups' }
MCPTool class >> repositoriesGroupName [

	^ 'repositories'
]

{ #category : 'metadata - groups' }
MCPTool class >> runtimeGroupName [

	^ 'runtime'
]

{ #category : 'metadata' }
MCPTool class >> shouldAutoRegister [

	^ self isBuiltIn
]

{ #category : 'metadata - groups' }
MCPTool class >> testsGroupName [

	^ 'tests'
]

{ #category : 'metadata - groups' }
MCPTool class >> toolCatalogGroupName [

	^ 'tool-catalog'
]

{ #category : 'scripts' }
MCPTool class >> toolGroups [

	^ MCPToolRegistry default publicToolGroups
]

{ #category : 'scripts' }
MCPTool class >> toolIconFormOf: aToolClass [

	^ Form fromBase64String: (aToolClass toolIcons first src copyAfter: $,)
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

{ #category : 'metadata - groups' }
MCPTool class >> uiGroupName [

	^ 'ui'
]

{ #category : 'metadata' }
MCPTool >> additionalKeywords [

	^ #(  )
]

{ #category : 'metadata' }
MCPTool >> annotations [

	^ MCPStructureToolAnnotations mayModify
]

{ #category : 'accessing' }
MCPTool >> asJRPCJSON [

	| dictionary |
	dictionary := Dictionary new.
	self annotations ifNotNil: [ :toolAnnotations | dictionary at: #annotations put: toolAnnotations asJRPCJSON ].
	self description ifNotNil: [ dictionary at: #description put: self description asJRPCJSON ].
	self inputSchema ifNotNil: [ dictionary at: #inputSchema put: self inputSchema asJRPCJSON ].
	self name ifNotNil: [ dictionary at: #name put: self name asJRPCJSON ].
	self title ifNotNil: [ dictionary at: #title put: self title asJRPCJSON ].
	^ dictionary
]

{ #category : 'private - schema' }
MCPTool >> booleanSchemaPropertyNamed: propertyName description: propertyDescription [

	^ self schemaPropertyNamed: propertyName type: 'boolean' description: propertyDescription
]

{ #category : 'private - schema' }
MCPTool >> booleanSchemaPropertyNamed: propertyName description: propertyDescription default: defaultValue [

	^ (self booleanSchemaPropertyNamed: propertyName description: propertyDescription)
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

{ #category : 'private - results' }
MCPTool >> contentTextForStructuredContent: structuredContent [
	"Answer the text block a caller reads: what happened, then the payload as lines. A tool overrides the rendering of its own data when its shape reads better another way."

	^ String streamContents: [ :stream |
			  self summaryAndWarningsOn: stream for: structuredContent.
			  structuredContent at: #data ifPresent: [ :data | self dataTextOn: stream for: data ].
			  structuredContent at: #error ifPresent: [ :error | self errorTextOn: stream for: error ] ]
]

{ #category : 'metadata' }
MCPTool >> contractIncludingOutputSchema: includeOutputSchema [

	| data |
	data := self metadata copy.
	data at: #inputSchema put: self inputSchema asJRPCJSON.
	includeOutputSchema ifTrue: [ data at: #outputSchema put: self outputSchema asJRPCJSON ].
	^ data
]

{ #category : 'private - results' }
MCPTool >> dataTextOn: stream for: data [
	"Render a payload as lines, in a reading order: what identifies the result first, then the blocks of text it carries. Sorting alphabetically alone buries a class name under its comment."

	| keys stated |
	stated := self keysStatedInSummary.
	keys := (data keys reject: [ :key | stated includes: key asSymbol ]) asSortedCollection: [ :left :right |
		        left asString <= right asString ].
	keys do: [ :key |
			(self isBlockValue: (data at: key)) ifFalse: [
					self
						valueTextOn: stream
						for: (data at: key)
						labelled: key asString
						indent: '' ] ].
	keys do: [ :key |
			(self isBlockValue: (data at: key)) ifTrue: [
					self
						valueTextOn: stream
						for: (data at: key)
						labelled: key asString
						indent: '' ] ]
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
MCPTool >> entriesTextOn: stream for: entries labelled: label indent: indent [
	"A list of records reads as one line each; a list of plain values reads as one line."

	(entries anySatisfy: [ :each | each isDictionary ]) ifFalse: [
			stream
				nextPut: Character lf;
				nextPutAll: indent;
				nextPutAll: label;
				nextPutAll: ': ';
				nextPutAll: (', ' join: (entries collect: [ :each | each asString ])).
			^ self ].
	entries do: [ :entry |
			stream
				nextPut: Character lf;
				nextPutAll: indent.
			entry isDictionary
				ifTrue: [
						(entry keys asSortedCollection: [ :left :right | left asString <= right asString ])
							do: [ :key |
									stream
										nextPutAll: key asString;
										nextPut: $=;
										nextPutAll: (entry at: key) asString ]
							separatedBy: [ stream space ] ]
				ifFalse: [ stream nextPutAll: entry asString ] ]
]

{ #category : 'private - results' }
MCPTool >> errorDetailsFor: anError [

	| context descriptionText details errorClassName message stackTrace |
	details := Dictionary new.
	errorClassName := anError class name asString.
	message := anError messageText ifNil: [ '' ] ifNotNil: [ :text | text asString ].
	details at: #errorClass put: errorClassName.
	details at: #message put: message.
	descriptionText := anError description.
	(descriptionText ~= errorClassName and: [ descriptionText ~= message ]) ifTrue: [ details at: #description put: descriptionText ].
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
	^ self errorResultText: (self failureMessageFor: anError) details: details
]

{ #category : 'error handling' }
MCPTool >> errorResultText: aString details: aDictionary [

	| details normalizedSummary structuredContent |
	normalizedSummary := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	details := aDictionary ifNil: [ Dictionary new ] ifNotNil: [ aDictionary copy ].
	details at: #message ifAbsentPut: [ normalizedSummary ].
	details at: #errorClass ifAbsentPut: [ 'ToolError' ].
	structuredContent := Dictionary new
		                     at: #summary put: normalizedSummary;
		                     at: #error put: details;
		                     yourself.
	^ MCPStructureErrorToolResult
		  content: { (self textContent: (self contentTextForStructuredContent: structuredContent)) }
		  structuredContent: structuredContent
]

{ #category : 'private - schema' }
MCPTool >> errorSchemaProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'errorClass'
			   type: 'string'
			   description: 'The Smalltalk exception class name describing the failure.').
		  (self
			   schemaPropertyNamed: 'errorCode'
			   type: 'string'
			   description: 'A tool-specific error code when the failure was signaled intentionally by the MCP implementation.').
		  (self schemaPropertyNamed: 'message' type: 'string' description: 'A concise error message describing the failure.').
		  (self
			   schemaPropertyNamed: 'description'
			   type: 'string'
			   description: 'A longer textual description of the failure when available.').
		  (self
			   schemaPropertyNamed: 'signalerContext'
			   type: 'string'
			   description: 'The signaler context recorded for the exception when available.').
		  (self
			   stringArraySchemaNamed: 'stackTrace'
			   description: 'A debug stack trace captured from the signaler context when available.'
			   itemDescription: 'One stack frame from the captured signaler chain, ordered from the signaling frame outward.') }
]

{ #category : 'error handling' }
MCPTool >> errorStackTraceForContext: aContext [

	^ ((self framesUpToCallerIn: (aContext stackOfSize: self errorStackTraceLimit)) collect: [ :each | each printString ]) asArray
]

{ #category : 'private - results' }
MCPTool >> errorStackTraceLimit [

	^ 20
]

{ #category : 'private - results' }
MCPTool >> errorTextOn: stream for: error [
	"The summary already carries the class, the message, and any suggestion the command phrased into it. What it does not carry is where the failure happened, or the selectors a receiver would have understood."

	error at: #suggestedSelectors ifPresent: [ :selectors |
			stream
				nextPut: Character lf;
				nextPutAll: 'Did you mean: ';
				nextPutAll: (', ' join: selectors) ].
	error at: #stackTrace ifPresent: [ :frames |
			frames do: [ :each |
					stream
						nextPut: Character lf;
						nextPutAll: each ] ]
]

{ #category : 'private - execution' }
MCPTool >> executeParsedRequestFrom: request do: executionBlock onError: errorBlock [
	"Parse the transport request inside the same exception boundary as execution.
	The error block receives the error and the parsed request, or nil if parsing failed.
	Every Warning and Notification is an Exception, so notifications are resumed here instead of failing the call."

	| parsedRequest |
	^ [
	  [
	  parsedRequest := self parsedRequestFromToolRequest: request.
	  executionBlock value: parsedRequest ]
		  on: Notification
		  do: [ :notification |
				  (self shouldResumeNotification: notification)
					  ifTrue: [ self resumeNotification: notification ]
					  ifFalse: [ notification pass ] ] ]
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
	message := anError messageText ifNil: [ '' ] ifNotNil: [ :text | text asString ].
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

{ #category : 'error handling' }
MCPTool >> framesUpToCallerIn: frames [
	"Drop the trailing frames that belong to the server rather than to the failing code: the dispatch and doIt scaffolding is identical on every failure and says nothing about why this one failed. An evaluation ends at its outermost doIt; any other call ends where the server's own classes begin. When nothing else is left the failure was in the server, so the whole stack is kept."

	| lastCallerFrame |
	lastCallerFrame := frames findLast: [ :each | each method selector == #DoIt ].
	lastCallerFrame = 0 ifTrue: [ lastCallerFrame := frames findLast: [ :each | (self isServerFrame: each) not ] ].
	lastCallerFrame = 0 ifTrue: [ ^ frames ].
	^ frames first: lastCallerFrame
]

{ #category : 'metadata' }
MCPTool >> groupName [

	^ self class groupName
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

	^ self schemaPropertyNamed: propertyName type: 'integer' description: propertyDescription
]

{ #category : 'private - schema' }
MCPTool >> integerSchemaPropertyNamed: propertyName description: propertyDescription default: defaultValue [

	^ (self integerSchemaPropertyNamed: propertyName description: propertyDescription)
		  default: defaultValue;
		  yourself
]

{ #category : 'private - results' }
MCPTool >> isBlockValue: value [
	"A block of text is read as a block: it belongs after the fields that identify the result, not sorted among them."

	^ value isString and: [ value includesSubstring: String cr ]
]

{ #category : 'error handling' }
MCPTool >> isServerFrame: aContext [

	^ aContext method methodClass
		  ifNil: [ false ]
		  ifNotNil: [ :methodClass | methodClass instanceSide name beginsWith: 'MCP' ]
]

{ #category : 'private - results' }
MCPTool >> keysStatedInSummary [
	"Answer the data keys whose value the summary already states in prose, so the text does not say it twice. A tool declares its own."

	^ #(  )
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
		  (#annotations -> self annotations asJRPCJSON).
		  (#keywords -> self keywords) } asDictionary
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

	^ MCPStructureIcon compositeBaseIconNamed: aBaseIconSymbol badgeIconNamed: aBadgeIconSymbol
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

{ #category : 'private - execution' }
MCPTool >> resumeNotification: aNotification [
	"Resume with the value the image itself would have produced. The default action may signal notifications of its own, and a handler is suspended while its block runs, so those would otherwise escape this boundary and fail the call: Deprecation>>defaultAction logs, and logging signals DeprecationPerformedNotification."

	^ aNotification resume: ([ aNotification defaultAction ]
			   on: Notification
			   do: [ :nested | self resumeNotification: nested ])
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

{ #category : 'private - schema' }
MCPTool >> shouldAdvertiseStringArrayItemDescription: anItemDescription [

	| itemDescriptionString |
	itemDescriptionString := anItemDescription ifNil: [ ^ false ] ifNotNil: [ :value | value asString trimBoth ].
	itemDescriptionString isEmpty ifTrue: [ ^ false ].
	(itemDescriptionString endsWith: ' name.') ifTrue: [ ^ false ].
	(#( 'Hierarchy root class.' ) includes: itemDescriptionString) ifTrue: [ ^ false ].
	^ true
]

{ #category : 'testing' }
MCPTool >> shouldRecordObservability [

	^ true
]

{ #category : 'testing' }
MCPTool >> shouldResumeNotification: aNotification [
	"A notification is not a failed call, so the boundary resumes it. A refactoring warning is the exception: it reports a change that breaks something, and a tool that may proceed anyway handles it itself behind force, so letting it reach the boundary unresumed is what aborts an unauthorized mutation."

	^ (aNotification isKindOf: RBRefactoringWarning) not
]

{ #category : 'private - schema' }
MCPTool >> standardOutputSchemaForDataProperties: dataProperties required: requiredFields [
	"The result carries no status field: isError already states on the wire whether the call failed, and the presence of data or error says the same again."

	| dataProperty errorProperty summaryProperty |
	dataProperty := self schemaPropertyNamed: 'data' type: 'object' description: 'Structured success payload.'.
	dataProperty
		properties: dataProperties;
		required: requiredFields;
		additionalProperties: false.
	errorProperty := self schemaPropertyNamed: 'error' type: 'object' description: 'Structured error information.'.
	errorProperty
		properties: self errorSchemaProperties;
		required: #( 'message' );
		additionalProperties: true.
	summaryProperty := self schemaPropertyNamed: 'summary' type: 'string' description: 'Human-readable result summary.'.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  summaryProperty.
				  self warningsSchemaProperty.
				  dataProperty.
				  errorProperty };
		  required: #( 'summary' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPTool >> stringArraySchemaNamed: aName [

	^ self stringArraySchemaNamed: aName description: nil itemDescription: nil
]

{ #category : 'private - schema' }
MCPTool >> stringArraySchemaNamed: aName description: aDescription itemDescription: anItemDescription [

	| itemsProperty |
	itemsProperty := MCPStructureProperties new
		                 type: 'string';
		                 yourself.
	(self shouldAdvertiseStringArrayItemDescription: anItemDescription) ifTrue: [ itemsProperty description: anItemDescription ].
	^ (self schemaPropertyNamed: aName type: 'array' description: aDescription)
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
	^ (self schemaPropertyNamed: propertyName type: 'array' description: propertyDescription)
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

	^ (self schemaPropertyNamed: propertyName type: 'string' description: propertyDescription)
		  enum: enumValues;
		  yourself
]

{ #category : 'private - schema' }
MCPTool >> stringEnumSchemaPropertyNamed: propertyName description: propertyDescription values: enumValues default: defaultValue [

	^ (self stringEnumSchemaPropertyNamed: propertyName description: propertyDescription values: enumValues)
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
		                     at: #summary put: normalizedSummary;
		                     at: #data put: aDictionary;
		                     yourself.
	warnings ifNotEmpty: [ structuredContent at: #warnings put: warnings ].
	^ MCPStructureCallToolResult
		  content: { (self textContent: (self contentTextForStructuredContent: structuredContent)) }
		  structuredContent: structuredContent
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
MCPTool >> summaryAndWarningsOn: stream for: structuredContent [
	"The opening of a plain-text result: what happened, then anything the call wants to qualify it with."

	stream nextPutAll: (structuredContent at: #summary ifAbsent: [ '' ]).
	(structuredContent at: #warnings ifAbsent: [ #(  ) ]) do: [ :each |
		stream
			nextPut: Character lf;
			nextPutAll: 'Warning: ';
			nextPutAll: each ]
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

{ #category : 'private - results' }
MCPTool >> valueTextOn: stream for: value labelled: label indent: indent [

	(value isNil or: [ value isCollection and: [ value isString not and: [ value isEmpty ] ] ]) ifTrue: [ ^ self ].
	value isDictionary ifTrue: [
			stream
				nextPut: Character lf;
				nextPutAll: indent;
				nextPutAll: label;
				nextPut: $:.
			^ (value keys asSortedCollection: [ :left :right | left asString <= right asString ]) do: [ :key |
					  self
						  valueTextOn: stream
						  for: (value at: key)
						  labelled: key asString
						  indent: indent , '  ' ] ].
	(value isCollection and: [ value isString not ]) ifTrue: [
			^ self
				  entriesTextOn: stream
				  for: value
				  labelled: label
				  indent: indent ].
	stream
		nextPut: Character lf;
		nextPutAll: indent;
		nextPutAll: label;
		nextPut: $:.
	(value isString and: [ value includesSubstring: String cr ])
		ifTrue: [
				stream nextPut: Character lf.
				stream nextPutAll: value withUnixLineEndings ]
		ifFalse: [
				stream
					space;
					nextPutAll: value asString ]
]

{ #category : 'private - schema' }
MCPTool >> warningsSchemaProperty [

	^ self stringArraySchemaNamed: 'warnings' description: 'Warnings produced by the tool.' itemDescription: 'Warning message.'
]
