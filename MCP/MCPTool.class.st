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

{ #category : 'private - methods' }
MCPTool >> compiledMethodEntriesFrom: compiledMethods filter: filterPattern filterMode: filterMode caseSensitive: caseSensitive includeSource: includeSource [

	| entries matcher needsSourceText |
	matcher := self
		           matcherForPattern: filterPattern
		           mode: filterMode
		           caseSensitive: caseSensitive.
	needsSourceText := includeSource or: [ filterPattern notNil ].
	entries := OrderedCollection new.
	compiledMethods do: [ :eachMethod |
		| entry info sourceText |
		info := MCPCompiledMethodInfo fromCompiledMethod: eachMethod.
		sourceText := needsSourceText
			              ifTrue: [ info source ]
			              ifFalse: [ nil ].
		entry := info asDictionaryIncludingSource: includeSource.
		(self
			 matchesFilterOnCompiledMethodEntry: entry
			 sourceText: sourceText
			 matcher: matcher) ifTrue: [ entries add: entry ] ].
	^ (entries asSortedCollection: [ :left :right |
		   (self compiledMethodEntryLabel: left)
		   <= (self compiledMethodEntryLabel: right) ]) asArray
]

{ #category : 'private - filtering' }
MCPTool >> compiledMethodEntryLabel: anEntry [

	^ self
		  methodReferenceForClassName: (anEntry at: #className)
		  selector: (anEntry at: #selector)
		  isClassSide: (anEntry at: #side) = 'class'
]

{ #category : 'private - methods' }
MCPTool >> compiledMethodScopeQueryFromArguments: arguments [

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
MCPTool >> description [

	^ description
]

{ #category : 'accessing' }
MCPTool >> description: anObject [

	description := anObject
]

{ #category : 'error handling' }
MCPTool >> errorContentFor: anError [

	^ { (self textContent: (self failureMessageFor: anError)) }
]

{ #category : 'private - results' }
MCPTool >> errorDetailsFor: anError [

	| details message |
	details := Dictionary new.
	message := anError messageText
		           ifNil: [ '' ]
		           ifNotNil: [ :text | text asString ].
	details at: #errorClass put: anError class name.
	details at: #message put: message.
	(anError description ~= anError class name and: [
		 anError description ~= message ]) ifTrue: [
		details at: #description put: anError description ].
	anError signalerContext ifNotNil: [ :context |
		details at: #signalerContext put: context printString ].
	^ details
]

{ #category : 'error handling' }
MCPTool >> errorResultFor: anError [

	^ self
		  errorResultText: (self failureMessageFor: anError)
		  details: (self errorDetailsFor: anError)
]

{ #category : 'error handling' }
MCPTool >> errorResultText: aString [

	^ self
		  errorResultText: aString
		  details: { (#message -> aString) } asDictionary
]

{ #category : 'error handling' }
MCPTool >> errorResultText: aString details: aDictionary [

	| details |
	details := aDictionary copy.
	details at: #message ifAbsentPut: [ aString ].
	details at: #errorClass ifAbsentPut: [ 'ToolError' ].
	^ MCPStructureErrorToolResult
		  content: { (self textContent: aString) }
		  structuredContent: {
				  (#status -> 'error').
				  (#error -> details) } asDictionary
]

{ #category : 'private - schema' }
MCPTool >> errorSchemaProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'errorClass'
			   type: 'string'
			   description:
			   'The Smalltalk exception class name when a tool fails.').
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
			   'The signaler context recorded for the exception when available.') }
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
MCPTool >> filterTextForCompiledMethodEntry: anEntry sourceText: sourceText [

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
			  nextPutAll: (self compiledMethodEntryLabel: anEntry).
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
	handler := [ :args |  ]
]

{ #category : 'accessing' }
MCPTool >> inputSchema [

	^ inputSchema
]

{ #category : 'accessing' }
MCPTool >> inputSchema: anObject [

	inputSchema := anObject
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
MCPTool >> matchesFilterOnCompiledMethodEntry: anEntry sourceText: sourceText matcher: aMatcher [

	^ aMatcher value:
		  (self
			   filterTextForCompiledMethodEntry: anEntry
			   sourceText: sourceText)
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

{ #category : 'accessing' }
MCPTool >> outputSchema [

	^ outputSchema
]

{ #category : 'accessing' }
MCPTool >> outputSchema: anObject [

	outputSchema := anObject
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

	| dataProperty errorProperty |
	dataProperty := self
		                schemaPropertyNamed: 'data'
		                type: 'object'
		                description:
		                'The structured success payload returned by the tool.'.
	dataProperty
		properties: dataProperties;
		required: requiredFields;
		additionalProperties: false.
	errorProperty := self
		                 schemaPropertyNamed: 'error'
		                 type: 'object'
		                 description:
		                 'Structured error information when the tool returns isError=true.'.
	errorProperty
		properties: self errorSchemaProperties;
		required: #( 'message' );
		additionalProperties: true.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'status'
					   type: 'string'
					   description:
						   'The tool result status. Uses ok for success and error for tool-level failures.').
				  dataProperty.
				  errorProperty };
		  required: #( 'status' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - tests' }
MCPTool >> standardTestDataPropertiesIncludingMethodName: includeMethodName [

	| properties failingNamesProperty issuesProperty |
	properties := OrderedCollection withAll: {
			              (self
				               schemaPropertyNamed: 'className'
				               type: 'string'
				               description: 'The test class that was executed.').
			              (self
				               schemaPropertyNamed: 'runCount'
				               type: 'number'
				               description: 'The number of tests that ran.').
			              (self
				               schemaPropertyNamed: 'passedCount'
				               type: 'number'
				               description: 'The number of tests that passed.').
			              (self
				               schemaPropertyNamed: 'skippedCount'
				               type: 'number'
				               description:
				               'The number of tests that were skipped.').
			              (self
				               schemaPropertyNamed: 'failureCount'
				               type: 'number'
				               description: 'The number of failing tests.').
			              (self
				               schemaPropertyNamed: 'errorCount'
				               type: 'number'
				               description:
				               'The number of tests ending in errors.') }.
	includeMethodName ifTrue: [
		properties add: (self
				 schemaPropertyNamed: 'testMethodName'
				 type: 'string'
				 description: 'The single test method that was executed.') ].
	failingNamesProperty := self
		                        schemaPropertyNamed: 'failingTestNames'
		                        type: 'array'
		                        description:
		                        'Readable identifiers for tests that failed or errored.'.
	failingNamesProperty items: (MCPStructureProperties new
			 type: 'string';
			 description: 'A failing test identifier.';
			 yourself).
	properties add: failingNamesProperty.
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
		            #( 'className' 'runCount' 'passedCount' 'skippedCount'
		               'failureCount' 'errorCount' 'failingTestNames'
		               'issues' ).
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

{ #category : 'private - tests' }
MCPTool >> structuredDataForTestResult: aResult className: className testMethodName: testMethodName [

	| data issues failingNames |
	issues := aResult issueDetails asSortedCollection: [ :left :right |
		          (left at: #testName) <= (right at: #testName) ].
	failingNames := (issues select: [ :each |
		                 #( 'failure' 'error' ) includes: (each at: #kind) ])
		                collect: [ :each | each at: #testName ]
		                as: Array.
	data := Dictionary new.
	data at: #className put: className.
	testMethodName ifNotNil: [
		data at: #testMethodName put: testMethodName ].
	data at: #runCount put: aResult runCount.
	data at: #passedCount put: aResult passedCount.
	data at: #skippedCount put: aResult skippedCount.
	data at: #failureCount put: aResult failureCount.
	data at: #errorCount put: aResult errorCount.
	data at: #failingTestNames put: failingNames.
	data at: #issues put: issues asArray.
	^ data
]

{ #category : 'private - results' }
MCPTool >> successResultText: aSummary data: aDictionary [

	^ MCPStructureCallToolResult
		  content: { (self textContent: aSummary) }
		  structuredContent: {
				  (#status -> 'ok').
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
					                  schemaPropertyNamed: 'testName'
					                  type: 'string'
					                  description:
						                  'A readable test identifier combining class and method.').
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
			                    'testName' 'errorClass' 'message' );
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
