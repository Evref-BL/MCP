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
			   MCPToolImplementors.
			   MCPToolReferences.
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

{ #category : 'private - arguments' }
MCPTool >> argumentNamed: anArgumentName in: arguments ifAbsent: aBlock [

	arguments ifNil: [ ^ aBlock value ].
	^ arguments
		  at: anArgumentName asSymbol
		  ifAbsent: [
		  arguments at: anArgumentName asString ifAbsent: aBlock ]
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

{ #category : 'private - methods' }
MCPTool >> behaviorNamed: aClassName classSide: aBoolean [

	| targetClass |
	targetClass := self class environment at: aClassName asSymbol.
	^ aBoolean
		  ifTrue: [ targetClass classSide ]
		  ifFalse: [ targetClass ]
]

{ #category : 'private - arguments' }
MCPTool >> booleanArgumentNamed: anArgumentName in: arguments default: aBoolean [

	| normalized value |
	value := self
		         argumentNamed: anArgumentName
		         in: arguments
		         ifAbsent: [ ^ aBoolean ].
	value ifNil: [ ^ aBoolean ].
	(value == true or: [ value == false ]) ifTrue: [ ^ value ].
	normalized := value asString trimBoth asLowercase.
	normalized = 'true' ifTrue: [ ^ true ].
	normalized = 'false' ifTrue: [ ^ false ].
	Error signal: anArgumentName asString , ' must be a boolean.'
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

{ #category : 'defaults' }
MCPTool >> defaultDescription [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPTool >> defaultHandler [

	^ [ :arguments |  ]
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
MCPTool >> executeWithArguments: anArgument [
	"You can also overide me to make things easier to manage"

	^ handler value: anArgument
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

{ #category : 'private - filtering' }
MCPTool >> filterTextForMethodEntry: anEntry sourceText: sourceText [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (anEntry at: #selector);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #className);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #side);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #packageName);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #protocol);
			  nextPutAll: ' ';
			  nextPutAll: (self methodEntryLabel: anEntry).
		  sourceText ifNotNil: [
			  stream
				  nextPutAll: ' ';
				  nextPutAll: sourceText ] ]
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

	| discriminatorProperty required |
	discriminatorProperty := MCPStructureProperties new
		                         name: propertyName;
		                         type: 'string';
		                         const: propertyValue;
		                         yourself.
	required := OrderedCollection new.
	requireDiscriminator ifTrue: [ required add: propertyName ].
	requiredFields do: [ :each |
		(required includes: each) ifFalse: [ required add: each ] ].
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { discriminatorProperty };
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

{ #category : 'private - filtering' }
MCPTool >> matcherForPattern: aPattern mode: aMode caseSensitive: aBoolean [

	| normalizedPattern regex |
	aPattern ifNil: [ ^ [ :candidate | true ] ].
	aMode = 'regex' ifTrue: [
		regex := aBoolean
			         ifTrue: [ aPattern asRegex ]
			         ifFalse: [ aPattern asRegexIgnoringCase ].
		^ [ :candidate |
		  regex search:
			  (candidate ifNil: [ '' ] ifNotNil: [ candidate asString ]) ] ].
	normalizedPattern := self
		                     normalizeFilterString: aPattern
		                     caseSensitive: aBoolean.
	aMode = 'substring' ifTrue: [
		^ [ :candidate |
		  (self normalizeFilterString: candidate caseSensitive: aBoolean)
			  includesSubstring: normalizedPattern ] ].
	aMode = 'prefix' ifTrue: [
		^ [ :candidate |
		  (self normalizeFilterString: candidate caseSensitive: aBoolean)
			  beginsWith: normalizedPattern ] ].
	aMode = 'exact' ifTrue: [
		^ [ :candidate |
		  (self normalizeFilterString: candidate caseSensitive: aBoolean)
		  = normalizedPattern ] ].
	Error signal: 'Unsupported filter mode: ' , aMode
]

{ #category : 'private - filtering' }
MCPTool >> matchesFilterOnMethodEntry: anEntry sourceText: sourceText matcher: aMatcher [

	^ aMatcher value:
		  (self filterTextForMethodEntry: anEntry sourceText: sourceText)
]

{ #category : 'private - methods' }
MCPTool >> methodEntriesFrom: compiledMethods filter: filterPattern filterMode: filterMode caseSensitive: caseSensitive includeSource: includeSource [

	| entries matcher needsSourceText |
	matcher := self
		           matcherForPattern: filterPattern
		           mode: filterMode
		           caseSensitive: caseSensitive.
	needsSourceText := includeSource or: [ filterPattern notNil ].
	entries := OrderedCollection new.
	compiledMethods do: [ :eachMethod |
		| entry info sourceText |
		info := MCPCompiledMethodInfo fromMethod: eachMethod.
		sourceText := needsSourceText
			              ifTrue: [ info source ]
			              ifFalse: [ nil ].
		entry := info asDictionaryIncludingSource: includeSource.
		includeSource ifTrue: [ entry at: #source put: sourceText ].
		(self
			 matchesFilterOnMethodEntry: entry
			 sourceText: sourceText
			 matcher: matcher) ifTrue: [ entries add: entry ] ].
	^ (entries asSortedCollection: [ :left :right |
		   (self methodEntryLabel: left)
		   <= (self methodEntryLabel: right) ]) asArray
]

{ #category : 'private - filtering' }
MCPTool >> methodEntryLabel: anEntry [

	^ self
		  methodReferenceForClassName: (anEntry at: #className)
		  selector: (anEntry at: #selector)
		  isClassSide: (anEntry at: #side) = 'class'
]

{ #category : 'private - methods' }
MCPTool >> methodReferenceForBehavior: aBehavior selector: aSelector [

	^ String streamContents: [ :stream |
		  stream nextPutAll: (self targetNameForBehavior: aBehavior).
		  stream nextPutAll: '>>'.
		  stream nextPutAll: aSelector asString ]
]

{ #category : 'private - methods' }
MCPTool >> methodReferenceForClassName: aClassName selector: aSelector isClassSide: isClassSide [

	^ String streamContents: [ :stream |
		  stream nextPutAll: aClassName.
		  isClassSide ifTrue: [ stream nextPutAll: ' class' ].
		  stream
			  nextPutAll: '>>';
			  nextPutAll: aSelector ]
]

{ #category : 'private - methods' }
MCPTool >> methodScopeQueryFromArguments: arguments [

	^ MCPCompiledMethodScopeQuery
		  scope: (self stringArgumentNamed: 'scope' in: arguments)
		  packageNames:
		  (self
			   argumentNamed: 'packageNames'
			   in: arguments
			   ifAbsent: [ nil ])
		  classNames:
		  (self argumentNamed: 'classNames' in: arguments ifAbsent: [ nil ])
		  side: (self stringArgumentNamed: 'side' in: arguments)
]

{ #category : 'accessing' }
MCPTool >> name [

	^ name
]

{ #category : 'accessing' }
MCPTool >> name: anObject [

	name := anObject
]

{ #category : 'private - arguments' }
MCPTool >> nonNegativeIntegerArgumentNamed: anArgumentName in: arguments default: anInteger [

	| value |
	value := self
		         argumentNamed: anArgumentName
		         in: arguments
		         ifAbsent: [ ^ anInteger ].
	value ifNil: [ ^ anInteger ].
	(value isInteger and: [ value >= 0 ]) ifTrue: [ ^ value ].
	Error signal:
		anArgumentName asString , ' must be a non-negative integer.'
]

{ #category : 'private - filtering' }
MCPTool >> normalizeFilterString: aValue caseSensitive: aBoolean [

	| normalized |
	normalized := aValue
		              ifNil: [ '' ]
		              ifNotNil: [ :value | value asString ].
	^ aBoolean
		  ifTrue: [ normalized ]
		  ifFalse: [ normalized asLowercase ]
]

{ #category : 'private - arguments' }
MCPTool >> normalizedFilterModeFrom: arguments [

	| mode |
	mode := (self stringArgumentNamed: 'filterMode' in: arguments)
		        ifNil: [ ^ 'substring' ].
	mode := mode asLowercase.
	(#( 'substring' 'prefix' 'exact' 'regex' ) includes: mode) ifFalse: [
		Error signal:
			'filterMode must be one of substring, prefix, exact, or regex.' ].
	^ mode
]

{ #category : 'private - arguments' }
MCPTool >> normalizedSideFrom: arguments [

	| side |
	side := (self stringArgumentNamed: 'side' in: arguments) ifNil: [
		        ^ 'both' ].
	side := side asLowercase.
	(#( 'instance' 'class' 'both' ) includes: side) ifFalse: [
		Error signal: 'side must be one of instance, class, or both.' ].
	^ side
]

{ #category : 'private - arguments' }
MCPTool >> normalizedStringCollection: aValue argumentName: anArgumentName [

	| normalized value values |
	aValue ifNil: [ ^ #(  ) ].
	value := aValue.
	(value isString or: [ value isSymbol ]) ifTrue: [ value := { value } ].
	(value isCollection and: [ value isString not ]) ifFalse: [
		Error signal: anArgumentName , ' must be an array of strings.' ].
	values := OrderedCollection new.
	value do: [ :each |
		normalized := each asString trimBoth.
		normalized isEmpty ifFalse: [ values add: normalized ] ].
	^ values asArray
]

{ #category : 'accessing' }
MCPTool >> outputSchema [

	^ outputSchema
]

{ #category : 'accessing' }
MCPTool >> outputSchema: anObject [

	outputSchema := anObject
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
MCPTool >> pngHorizontallyFlippedIconNamed: anIconSymbol [

	^ MCPStructureIcon horizontallyFlippedPngIconNamed: anIconSymbol
]

{ #category : 'private - icons' }
MCPTool >> pngIconNamed: anIconSymbol [

	^ MCPStructureIcon pngIconNamed: anIconSymbol
]

{ #category : 'private - icons' }
MCPTool >> pngSizeStringForForm: aForm [

	^ aForm width asString , 'x' , aForm height asString
]

{ #category : 'private - schema' }
MCPTool >> schemaPropertyNamed: aName type: aType description: aDescription [

	^ MCPStructureProperties new
		  name: aName;
		  type: aType;
		  description: aDescription;
		  yourself
]

{ #category : 'private - arguments' }
MCPTool >> selectorStringFrom: arguments [

	^ self stringArgumentNamed: 'selector' in: arguments
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

{ #category : 'private - tests' }
MCPTool >> standardTestDataPropertiesIncludingMethodName: includeMethodName [

	| issuesProperty properties |
	properties := OrderedCollection withAll: {
			              (self
				               schemaPropertyNamed: 'className'
				               type: 'string'
				               description: 'The test class that was executed.').
			              (self
				               integerSchemaPropertyNamed: 'runCount'
				               description: 'The number of tests that ran.') }.
	includeMethodName ifTrue: [
		properties add: (self
				 schemaPropertyNamed: 'testMethodName'
				 type: 'string'
				 description: 'The single test method that was executed.') ].
	issuesProperty := self
		                  schemaPropertyNamed: 'issues'
		                  type: 'array'
		                  description:
		                  'Detailed issues captured while running tests.'.
	issuesProperty items: self testIssueObjectSchema.
	properties add: issuesProperty.
	^ properties asArray
]

{ #category : 'private - tests' }
MCPTool >> standardTestRequiredFieldsIncludingMethodName: includeMethodName [

	| required |
	required := OrderedCollection withAll:
		            #( 'className' 'runCount' 'issues' ).
	includeMethodName ifTrue: [ required add: 'testMethodName' ].
	^ required asArray
]

{ #category : 'private - arguments' }
MCPTool >> stringArgumentNamed: anArgumentName in: arguments [

	| value |
	value := self
		         argumentNamed: anArgumentName
		         in: arguments
		         ifAbsent: [ ^ nil ].
	value ifNil: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ value ]
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

{ #category : 'private - tests' }
MCPTool >> structuredDataForTestResult: aResult className: className testMethodName: testMethodName [

	| data issues |
	issues := (aResult issueDetails asSortedCollection: [ :left :right |
		           (left at: #testName) <= (right at: #testName) ])
		          collect: [ :each |
			          | issue |
			          issue := each copy.
			          issue removeKey: #testName ifAbsent: [  ].
			          issue ].
	data := Dictionary new.
	data at: #className put: className.
	testMethodName ifNotNil: [
		data at: #testMethodName put: testMethodName ].
	data at: #runCount put: aResult runCount.
	data at: #issues put: issues asArray.
	^ data
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

{ #category : 'private - methods' }
MCPTool >> targetNameForBehavior: aBehavior [

	^ aBehavior isMeta
		  ifTrue: [ aBehavior instanceSide name , ' class' ]
		  ifFalse: [ aBehavior name ]
]

{ #category : 'private - tests' }
MCPTool >> testIssueObjectSchema [

	| issueProperty |
	issueProperty := MCPStructureProperties new
		                 type: 'object';
		                 description:
			                 'A single test issue recorded while running tests.';
		                 properties: {
				                 (self
					                  schemaPropertyNamed: 'kind'
					                  type: 'string'
					                  description:
						                  'The issue category, such as failure, error, or skipped.').
				                 (self
					                  schemaPropertyNamed: 'className'
					                  type: 'string'
					                  description:
						                  'The test class that produced the issue.').
				                 (self
					                  schemaPropertyNamed: 'testMethodName'
					                  type: 'string'
					                  description:
						                  'The test method that produced the issue.').
				                 (self
					                  schemaPropertyNamed: 'errorClass'
					                  type: 'string'
					                  description:
						                  'The exception class captured for the issue.').
				                 (self
					                  schemaPropertyNamed: 'message'
					                  type: 'string'
					                  description:
						                  'The exception message for the issue.').
				                 (self
					                  schemaPropertyNamed: 'description'
					                  type: 'string'
					                  description:
						                  'A longer textual description of the issue when available.').
				                 (self
					                  schemaPropertyNamed: 'signalerContext'
					                  type: 'string'
					                  description:
						                  'The signaler context captured for the issue when available.') };
		                 required:
			                 #( 'kind' 'className' 'testMethodName'
			                    'errorClass' 'message' );
		                 additionalProperties: false;
		                 yourself.
	^ issueProperty
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

{ #category : 'validating' }
MCPTool >> validateArguments: arguments [

	| dictionary missingArguments requiredArguments |
	self inputSchema ifNil: [ ^ self ].
	requiredArguments := self inputSchema required ifNil: [ ^ self ].
	dictionary := arguments ifNil: [ Dictionary new ].
	missingArguments := requiredArguments reject: [ :each |
		                    | hasString hasSymbol stringKey symbolKey |
		                    stringKey := each asString.
		                    symbolKey := each asSymbol.
		                    hasString := (dictionary includesKey: stringKey)
			                                 and: [
			                                 (dictionary at: stringKey) notNil ].
		                    hasSymbol := (dictionary includesKey: symbolKey)
			                                 and: [
			                                 (dictionary at: symbolKey) notNil ].
		                    hasString or: [ hasSymbol ] ].
	missingArguments ifNotEmpty: [ JRPCInvalidParameters signal ]
]

{ #category : 'private - schema' }
MCPTool >> warningsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'warnings'
		  description:
		  'Human-readable warnings associated with the tool result. Empty when no warnings were produced.'
		  itemDescription: 'A warning message.'
]
