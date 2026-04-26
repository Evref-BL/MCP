"
Runs test classes or selected test methods and returns structured results. It is the testing bridge for the MCP server.
"
Class {
	#name : 'MCPToolRunTests',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - execution' }
MCPToolRunTests >> commandForRequest: runTestsRequest [

	^ MCPRunTestsCommand tool: self request: runTestsRequest
]

{ #category : 'private - errors' }
MCPToolRunTests >> compactTestNameFrom: testRequest [

	| className testMethodName |
	(testRequest respondsTo: #displayName) ifTrue: [
		^ testRequest displayName ].
	(testRequest respondsTo: #at:ifAbsent:) ifFalse: [
		^ testRequest asString ].
	className := testRequest
		             at: #className
		             ifAbsent: [
		             testRequest at: 'className' ifAbsent: [ nil ] ].
	className ifNil: [ ^ testRequest asString ].
	testMethodName := testRequest
		                  at: #testMethodName
		                  ifAbsent: [
		                  testRequest at: 'testMethodName' ifAbsent: [ nil ] ].
	^ testMethodName
		  ifNil: [ className asString ]
		  ifNotNil: [ className asString , '>>' , testMethodName asString ]
]

{ #category : 'private' }
MCPToolRunTests >> compactTestNamesFrom: testRequests [

	^ (testRequests collect: [ :each | self compactTestNameFrom: each ])
		  asArray
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultDescription [

	^ 'Run test classes or individual test methods as a batch and return aggregated results.'
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultIcons [

	^ { (self pngIconNamed: #testRunner) }
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  ((MCPStructureProperties new
					    name: 'tests';
					    type: 'array';
					    description: 'The test execution requests to run as a batch.')
					   items: self testRequestObjectSchema;
					   yourself).
				  (self
					   integerSchemaPropertyNamed: 'timeoutSeconds'
					   description:
					   'Server-side timeout for the batch. Use 0 to return immediately with all tests listed in unrunTests.'
					   default: self defaultTimeoutSeconds) };
		  required: #( 'tests' );
		  yourself
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultName [

	^ 'run-tests'
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultOutputSchema [

	| resultsProperty unrunTestsProperty |
	resultsProperty := self
		                   schemaPropertyNamed: 'results'
		                   type: 'array'
		                   description:
		                   'Structured results for each test execution request in the batch that completed before timeout.'.
	resultsProperty items: self testResultObjectSchema.
	unrunTestsProperty := self
		                      schemaPropertyNamed: 'unrunTests'
		                      type: 'array'
		                      description:
		                      'Test execution requests that did not run because the batch timed out. Pass this array to run-tests to continue from the timeout point.'.
	unrunTestsProperty items: self testRequestObjectSchema.
	^ self
		  standardOutputSchemaForDataProperties: {
				  resultsProperty.
				  (self
					   booleanSchemaPropertyNamed: 'timedOut'
					   description:
					   'Whether the batch stopped early because timeoutSeconds elapsed.').
				  unrunTestsProperty }
		  required: #( 'results' )
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultTimeoutSeconds [

	^ 90
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultTitle [

	^ 'Run Tests'
]

{ #category : 'private' }
MCPToolRunTests >> errorResultForError: anError tests: testRequests [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultText: anError messageText
			  details: anError structuredDetails ].
	^ self
		  errorResultText:
		  (self failureMessageForTests: testRequests error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#tests -> (self compactTestNamesFrom: testRequests)) }
				  asDictionary
]

{ #category : 'executing' }
MCPToolRunTests >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :runTestsRequest |
			  | data result |
			  result := (self commandForRequest: runTestsRequest) execute.
			  data := result asDictionary.
			  self
				  successResultText: (self successSummaryForData: data)
				  data: data ]
		  onError: [ :error :runTestsRequest |
			  self errorResultForError: error tests: (self
					   testRequestsForErrorFromParsedRequest: runTestsRequest
					   rawRequest: request) ]
]

{ #category : 'private' }
MCPToolRunTests >> failureMessageForTests: testRequests error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to run tests: ';
			  nextPutAll:
				  (', ' join: (self compactTestNamesFrom: testRequests));
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - request' }
MCPToolRunTests >> parsedRequestFromToolRequest: request [

	^ MCPRunTestsRequest fromRequest: request tool: self
]

{ #category : 'private - tests' }
MCPToolRunTests >> standardTestDataPropertiesIncludingMethodName: includeMethodName [

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
MCPToolRunTests >> standardTestRequiredFieldsIncludingMethodName: includeMethodName [

	| required |
	required := OrderedCollection withAll:
		            #( 'className' 'runCount' 'issues' ).
	includeMethodName ifTrue: [ required add: 'testMethodName' ].
	^ required asArray
]

{ #category : 'private' }
MCPToolRunTests >> successSummaryForData: data [

	| failureLikeCount results runCount selectionCount selectionWord timedOut unrunCount |
	results := data at: #results.
	selectionCount := results size.
	selectionWord := selectionCount = 1
		                 ifTrue: [ 'test selection' ]
		                 ifFalse: [ 'test selections' ].
	runCount := results
		            inject: 0
		            into: [ :sum :each | sum + (each at: #runCount) ].
	failureLikeCount := results inject: 0 into: [ :sum :each |
		                    sum + ((each at: #issues) count: [ :issue |
			                     #( 'failure' 'error' ) includes:
				                     (issue at: #kind) ]) asInteger ].
	timedOut := data at: #timedOut ifAbsent: [ false ].
	unrunCount := (data at: #unrunTests ifAbsent: [ #(  ) ]) size.
	^ String streamContents: [ :stream |
		  timedOut ifTrue: [ stream nextPutAll: 'Timed out. ' ].
		  stream
			  nextPutAll: 'Executed ';
			  nextPutAll: selectionCount asString;
			  nextPutAll: ' ';
			  nextPutAll: selectionWord;
			  nextPutAll: ' covering ';
			  nextPutAll: runCount asString;
			  nextPutAll: ' tests.'.
		  failureLikeCount > 0 ifTrue: [
			  stream
				  space;
				  nextPutAll: failureLikeCount asString;
				  nextPutAll: ' failures/errors were reported.' ].
		  timedOut ifTrue: [
			  stream
				  space;
				  nextPutAll: unrunCount asString;
				  nextPutAll: ' test requests remain in unrunTests.' ] ]
]

{ #category : 'private - tests' }
MCPToolRunTests >> testIssueObjectSchema [

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

{ #category : 'private' }
MCPToolRunTests >> testRequestObjectSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'A single test execution request in the batch.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The test class to run.').
				  (self
					   schemaPropertyNamed: 'testMethodName'
					   type: 'string'
					   description:
						   'The single test method to run. Omit this to run the full class suite.') };
		  required: #( 'className' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - errors' }
MCPToolRunTests >> testRequestsForErrorFromParsedRequest: runTestsRequest rawRequest: rawRequest [

	runTestsRequest ifNotNil: [ ^ runTestsRequest testRequests ].
	^ [
	  (rawRequest objectCollectionArgumentNamed: 'tests') collect: [
		  :each |
		  [ MCPTestRunRequest fromValue: each usingToolRequest: rawRequest ]
			  on: Exception
			  do: [ :ignored | each ] ] ]
		  on: Exception
		  do: [ :ignored | #(  ) ]
]

{ #category : 'private' }
MCPToolRunTests >> testResultObjectSchema [

	| properties |
	properties := OrderedCollection withAll:
		              (self standardTestDataPropertiesIncludingMethodName:
			               false).
	properties add: (self
			 schemaPropertyNamed: 'testMethodName'
			 type: 'string'
			 description:
			 'The single test method that was executed when the batch entry targeted one method.').
	^ MCPStructureProperties new
		  type: 'object';
		  description:
			  'Structured results for one test execution request in the batch.';
		  properties: properties asArray;
		  required:
			  (self standardTestRequiredFieldsIncludingMethodName: false);
		  additionalProperties: false;
		  yourself
]
