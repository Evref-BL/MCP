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
