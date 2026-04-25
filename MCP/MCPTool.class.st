"
Base class for MCP tools exposed by the server. It owns common tool metadata, schema building, and result/error helpers.
"
Class {
	#name : 'MCPTool',
	#superclass : 'Object',
	#instVars : [
		'name',
		'title',
		'description',
		'icons',
		'inputSchema',
		'handler',
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

{ #category : 'scripts' }
MCPTool class >> displayTools [

	<script>
	| content contentLayout heading image label rowLayout window |
	content := SpPresenter new.
	contentLayout := SpBoxLayout newTopToBottom
		                 spacing: 3;
		                 borderWidth: 9;
		                 yourself.
	self toolGroups do: [ :group |
		heading := content newLabel.
		heading
			label: group key;
			displayBold: [ :ignored | true ].
		contentLayout add: heading expand: false.
		group value do: [ :toolClass |
			image := content newImage.
			image
				image: (self toolIconFormOf: toolClass);
				autoScale: false.
			label := content newLabel.
			label label: toolClass new title.
			rowLayout := SpBoxLayout newLeftToRight
				             spacing: 6;
				             hAlignStart;
				             vAlignCenter;
				             add: image;
				             add: label;
				             yourself.
			contentLayout add: rowLayout ] ].
	content layout: contentLayout.
	window := SpWindowPresenter presenter: (content newPresenter
			           layout: (SpScrollableLayout with: content);
			           yourself).
	window
		title: 'MCP Tools';
		initialExtent: 200 @ 620.
	^ window open
]

{ #category : 'testing' }
MCPTool class >> isAbstract [

	^ self = MCPTool
]

{ #category : 'scripts' }
MCPTool class >> toolGroups [

	^ {
		  (#Packages -> { MCPToolFindPackages }).
		  (#Classes -> {
			   MCPToolFindClasses.
			   MCPToolInspectClass.
			   MCPToolEditClass.
			   MCPToolRemoveClasses }).
		  (#Methods -> {
			   MCPToolFindMethods.
			   MCPToolInspectMethod.
			   MCPToolEditMethod.
			   MCPToolRemoveMethods }).
		  (#Tests -> { MCPToolRunTests }).
		  (#Scripting -> { MCPToolEvaluate }) }
]

{ #category : 'scripts' }
MCPTool class >> toolIconFormOf: aToolClass [

	^ Form fromBase64String:
		  (aToolClass new icons first src copyAfter: $,)
]

{ #category : 'accessing' }
MCPTool >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self description ifNotNil: [
		dic at: #description put: self description asJRPCJSON ].
	self icons ifNotNil: [ dic at: #icons put: self icons asJRPCJSON ].
	self inputSchema ifNotNil: [
		dic at: #inputSchema put: self inputSchema asJRPCJSON ].
	self outputSchema ifNotNil: [
		dic at: #outputSchema put: self outputSchema asJRPCJSON ].
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

{ #category : 'private - execution' }
MCPTool >> commandForRequest: aToolRequest [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPTool >> conditionalInputSchemaIf: conditionSchema thenRequired: requiredFields [

	| thenSchema |
	thenSchema := MCPStructureInputSchema new
		              type: 'object';
		              required: requiredFields;
		              additionalProperties: true;
		              yourself.
	^ MCPStructureInputSchema new
		  additionalProperties: true;
		  schemaKeyword: #if put: conditionSchema;
		  schemaKeyword: #then put: thenSchema;
		  yourself
]

{ #category : 'defaults' }
MCPTool >> defaultDescription [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPTool >> defaultHandler [

	^ [ :request |  ]
]

{ #category : 'defaults' }
MCPTool >> defaultIcons [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPTool >> defaultInputSchema [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPTool >> defaultName [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPTool >> defaultOutputSchema [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPTool >> defaultTitle [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPTool >> description [

	^ description
]

{ #category : 'accessing' }
MCPTool >> description: anObject [

	description := anObject
]

{ #category : 'private - results' }
MCPTool >> errorDetailsFor: anError [

	| descriptionText details message stackTrace |
	details := Dictionary new.
	message := (anError respondsTo: #messageText)
		           ifTrue: [
			           anError messageText
				           ifNil: [ '' ]
				           ifNotNil: [ :text | text asString ] ]
		           ifFalse: [ anError asString ].
	details at: #errorClass put: anError class name.
	details at: #message put: message.
	(anError respondsTo: #description) ifTrue: [
		descriptionText := anError description.
		(descriptionText ~= anError class name and: [
			 descriptionText ~= message ]) ifTrue: [
			details at: #description put: descriptionText ] ].
	(anError respondsTo: #signalerContext) ifTrue: [
		anError signalerContext ifNotNil: [ :context |
			details at: #signalerContext put: context printString.
			stackTrace := self errorStackTraceForContext: context.
			stackTrace ifNotEmpty: [ details at: #stackTrace put: stackTrace ] ] ].
	^ details
]

{ #category : 'error handling' }
MCPTool >> errorResultFor: anError [

	^ self
		  errorResultText: (self failureMessageFor: anError)
		  details: (self errorDetailsFor: anError)
]

{ #category : 'error handling' }
MCPTool >> errorResultText: aString details: aDictionary [

	| details normalizedSummary |
	normalizedSummary := aString
		                     ifNil: [ '' ]
		                     ifNotNil: [ aString asString ].
	details := aDictionary
		           ifNil: [ Dictionary new ]
		           ifNotNil: [ aDictionary copy ].
	details at: #message ifAbsentPut: [ normalizedSummary ].
	details at: #errorClass ifAbsentPut: [ 'ToolError' ].
	^ MCPStructureErrorToolResult
		  content: { (self textContent: normalizedSummary) }
		  structuredContent: {
				  (#status -> 'error').
				  (#summary -> normalizedSummary).
				  (#warnings -> #(  )).
				  (#error -> details) } asDictionary
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

{ #category : 'executing' }
MCPTool >> executeWithRequest: aRequest [
	"Subclasses may override me to manage execution directly."

	^ handler value: aRequest
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

{ #category : 'accessing' }
MCPTool >> handler [

	^ handler
]

{ #category : 'accessing' }
MCPTool >> handler: anObject [

	handler := anObject
]

{ #category : 'accessing' }
MCPTool >> icons [

	^ icons
]

{ #category : 'accessing' }
MCPTool >> icons: anObject [

	icons := anObject
]

{ #category : 'initialization' }
MCPTool >> initialize [

	super initialize.
	name := self defaultName.
	title := self defaultTitle.
	description := self defaultDescription.
	handler := self defaultHandler.
	inputSchema := self defaultInputSchema.
	outputSchema := self defaultOutputSchema.
	icons := self defaultIcons
]

{ #category : 'accessing' }
MCPTool >> inputSchema [

	^ inputSchema
]

{ #category : 'accessing' }
MCPTool >> inputSchema: anObject [

	inputSchema := anObject
]

{ #category : 'private - schema' }
MCPTool >> inputSchemaBranchForStringDiscriminatorNamed: propertyName value: propertyValue required: requiredFields requireDiscriminator: requireDiscriminator [

	^ self
		  inputSchemaBranchForStringDiscriminatorValues:
		  { (propertyName -> propertyValue) }
		  required: requiredFields
		  requireDiscriminators: requireDiscriminator
]

{ #category : 'private - schema' }
MCPTool >> inputSchemaBranchForStringDiscriminatorValues: discriminatorAssociations required: requiredFields requireDiscriminators: requireDiscriminators [

	| discriminatorProperties required |
	discriminatorProperties := discriminatorAssociations collect: [ :each |
		                           MCPStructureProperties new
			                           name: each key;
			                           type: 'string';
			                           const: each value;
			                           yourself ].
	required := OrderedCollection new.
	requireDiscriminators ifTrue: [
		discriminatorAssociations do: [ :each |
			(required includes: each key) ifFalse: [ required add: each key ] ] ].
	requiredFields do: [ :each |
		(required includes: each) ifFalse: [ required add: each ] ].
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: discriminatorProperties asArray;
		  required: required asArray;
		  additionalProperties: true;
		  yourself
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

{ #category : 'accessing' }
MCPTool >> name [

	^ name
]

{ #category : 'accessing' }
MCPTool >> name: anObject [

	name := anObject
]

{ #category : 'accessing' }
MCPTool >> outputSchema [

	^ outputSchema
]

{ #category : 'accessing' }
MCPTool >> outputSchema: anObject [

	outputSchema := anObject
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

	| bytes |
	bytes := ByteArray streamContents: [ :stream |
		         PNGReadWriter putForm: aForm onStream: stream ].
	^ 'data:image/png;base64,' , bytes base64Encoded
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

{ #category : 'private - schema' }
MCPTool >> standardOutputSchemaForDataProperties: dataProperties required: requiredFields [

	| dataProperty errorProperty statusProperty summaryProperty |
	dataProperty := self
		                schemaPropertyNamed: 'data'
		                type: 'object'
		                description:
		                'The structured success payload returned by the tool when status=ok.'.
	dataProperty
		properties: dataProperties;
		required: requiredFields;
		additionalProperties: false.
	errorProperty := self
		                 schemaPropertyNamed: 'error'
		                 type: 'object'
		                 description:
		                 'Structured error information when status=error.'.
	errorProperty
		properties: self errorSchemaProperties;
		required: #( 'message' );
		additionalProperties: true.
	statusProperty := self
		                  stringEnumSchemaPropertyNamed: 'status'
		                  description: 'The tool result status.'
		                  values: #( 'ok' 'error' ).
	summaryProperty := self
		                   schemaPropertyNamed: 'summary'
		                   type: 'string'
		                   description:
		                   'A concise human-readable summary of the tool result.'.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  statusProperty.
				  summaryProperty.
				  self warningsSchemaProperty.
				  dataProperty.
				  errorProperty };
		  required: #( 'status' 'summary' 'warnings' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPTool >> stringArraySchemaNamed: aName description: aDescription itemDescription: anItemDescription [

	| itemsProperty |
	itemsProperty := MCPStructureProperties new
		                 type: 'string';
		                 description: anItemDescription;
		                 yourself.
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

	| normalizedSummary warnings |
	normalizedSummary := aSummary
		                     ifNil: [ '' ]
		                     ifNotNil: [ aSummary asString ].
	warnings := warningStrings
		            ifNil: [ #(  ) ]
		            ifNotNil: [
		            (warningStrings collect: [ :each | each asString ])
			            asArray ].
	^ MCPStructureCallToolResult
		  content: { (self textContent: normalizedSummary) }
		  structuredContent: {
				  (#status -> 'ok').
				  (#summary -> normalizedSummary).
				  (#warnings -> warnings).
				  (#data -> aDictionary) } asDictionary
]

{ #category : 'private - results' }
MCPTool >> textContent: aString [

	^ MCPStructureTextContent text: aString
]

{ #category : 'accessing' }
MCPTool >> title [

	^ title
]

{ #category : 'accessing' }
MCPTool >> title: anObject [

	title := anObject
]

{ #category : 'private - schema' }
MCPTool >> warningsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'warnings'
		  description:
		  'Human-readable warnings associated with the tool result. Empty when no warnings were produced.'
		  itemDescription: 'A warning message.'
]
