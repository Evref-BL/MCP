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

{ #category : 'private' }
MCPToolRunTests >> addTestCasesFrom: aTestOrSuite to: testCases [

	(aTestOrSuite respondsTo: #tests) ifTrue: [
		aTestOrSuite tests do: [ :each |
			self addTestCasesFrom: each to: testCases ].
		^ self ].
	testCases add: aTestOrSuite
]

{ #category : 'private' }
MCPToolRunTests >> aggregateDataForResults: resultEntries timedOut: timedOut unrunTests: unrunTests [

	^ MCPRunTestsResult
		  results: resultEntries
		  timedOut: timedOut
		  unrunTests: unrunTests
]

{ #category : 'private - execution' }
MCPToolRunTests >> commandForRequest: runTestsRequest [

	^ MCPRunTestsCommand tool: self request: runTestsRequest
]

{ #category : 'private' }
MCPToolRunTests >> compactTestNamesFrom: testRequests [

	^ (testRequests collect: [ :each |
		   each at: #testMethodName ifAbsent: [ each at: #className ] ])
		  asArray
]

{ #category : 'private - timeout' }
MCPToolRunTests >> deadlineForTimeoutMilliseconds: timeoutMilliseconds [

	^ Time millisecondClockValue + timeoutMilliseconds
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

	| data result runTestsRequest |
	runTestsRequest := MCPRunTestsRequest new
		                   initializeTestRequests: #(  )
		                   timeoutMilliseconds: nil.
	^ [
	  runTestsRequest := self parsedRequestFromToolRequest: request.
	  result := (self commandForRequest: runTestsRequest) execute.
	  data := result asDictionary.
	  self
		  successResultText: (self successSummaryForData: data)
		  data: data ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForError: error
				  tests: runTestsRequest testRequests ]
]

{ #category : 'private' }
MCPToolRunTests >> failureMessageForTests: testRequests error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to run tests: ';
			  nextPutAll: (', ' join: (testRequests collect: [ :each |
								    | className testMethodName |
								    className := each at: #className.
								    testMethodName := each
									                      at: #testMethodName
									                      ifAbsent: [ nil ].
								    testMethodName
									    ifNil: [ className ]
									    ifNotNil: [ className , '>>' , testMethodName ] ]));
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - timeout' }
MCPToolRunTests >> hasTimedOutAt: deadline [

	^ (self millisecondsRemainingUntil: deadline) <= 0
]

{ #category : 'private - timeout' }
MCPToolRunTests >> millisecondsRemainingUntil: deadline [

	^ 0 max: deadline - Time millisecondClockValue
]

{ #category : 'private - request' }
MCPToolRunTests >> parsedRequestFromToolRequest: request [

	^ MCPRunTestsRequest fromRequest: request tool: self
]

{ #category : 'private' }
MCPToolRunTests >> resultForValidatedRequest: aDictionary deadline: deadline [

	| includeResult request result testCases testClass timedOutIndex testMethodName |
	request := aDictionary at: #request.
	testClass := aDictionary at: #class.
	testMethodName := request at: #testMethodName ifAbsent: [ nil ].
	testCases := self testCasesForValidatedRequest: aDictionary.
	result := MCPStructuredTestResult new.
	timedOutIndex := nil.
	testCases doWithIndex: [ :testCase :index |
		timedOutIndex ifNil: [
			(self runTestCase: testCase into: result deadline: deadline)
				ifTrue: [ timedOutIndex := index ] ] ].
	includeResult := timedOutIndex isNil or: [
		                 result runCount > 0 or: [
			                 result issueDetails notEmpty ] ].
	^ Dictionary new
		  at: #result put: (includeResult
				   ifTrue: [
					   self
						   structuredDataForTestResult: result
						   className: testClass name asString
						   testMethodName: testMethodName ]
				   ifFalse: [ nil ]);
		  at: #timedOut put: timedOutIndex notNil;
		  at: #unrunTests put: (timedOutIndex
				   ifNil: [ #(  ) ]
				   ifNotNil: [
					   self
						   testRequestsForTestCases: testCases
						   startingAt: timedOutIndex ]);
		  yourself
]

{ #category : 'private - timeout' }
MCPToolRunTests >> runTestCase: aTestCase into: aResult deadline: deadline [

	| remaining |
	remaining := self millisecondsRemainingUntil: deadline.
	remaining <= 0 ifTrue: [ ^ true ].
	^ [
	  aTestCase run: aResult.
	  false ] valueWithinMilliseconds: remaining onTimeout: [ true ]
]

{ #category : 'private' }
MCPToolRunTests >> runValidatedRequests: validatedRequests deadline: deadline [

	| outcome resultEntries unrunTests |
	resultEntries := OrderedCollection new.
	1 to: validatedRequests size do: [ :index |
		(self hasTimedOutAt: deadline) ifTrue: [
			unrunTests := self
				              unrunTestsFrom: validatedRequests
				              startingAt: index.
			^ self
				  aggregateDataForResults: resultEntries
				  timedOut: true
				  unrunTests: unrunTests ].
		outcome := self
			           resultForValidatedRequest: (validatedRequests at: index)
			           deadline: deadline.
		(outcome at: #result) ifNotNil: [ :resultEntry |
			resultEntries add: resultEntry ].
		(outcome at: #timedOut) ifTrue: [
			unrunTests := OrderedCollection new.
			unrunTests addAll: (outcome at: #unrunTests).
			unrunTests addAll:
				(self unrunTestsFrom: validatedRequests startingAt: index + 1).
			^ self
				  aggregateDataForResults: resultEntries
				  timedOut: true
				  unrunTests: unrunTests ] ].
	^ self
		  aggregateDataForResults: resultEntries
		  timedOut: false
		  unrunTests: #(  )
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

{ #category : 'private - tests' }
MCPToolRunTests >> structuredDataForTestResult: aResult className: className testMethodName: testMethodName [

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

{ #category : 'private' }
MCPToolRunTests >> testCasesForValidatedRequest: aDictionary [

	| request suite testClass testMethodName |
	request := aDictionary at: #request.
	testClass := aDictionary at: #class.
	testMethodName := request at: #testMethodName ifAbsent: [ nil ].
	testMethodName ifNotNil: [
		^ { (testClass selector: testMethodName asSymbol) } ].
	suite := testClass suite.
	^ self testCasesFromSuite: suite
]

{ #category : 'private' }
MCPToolRunTests >> testCasesFromSuite: aSuite [

	| testCases |
	testCases := OrderedCollection new.
	self addTestCasesFrom: aSuite to: testCases.
	^ testCases asArray
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
MCPToolRunTests >> testRequestForTestCase: aTestCase [

	| request |
	request := Dictionary new.
	request at: #className put: aTestCase class name asString.
	request at: #testMethodName put: aTestCase selector asString.
	^ request
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

{ #category : 'private' }
MCPToolRunTests >> testRequestsForTestCases: testCases startingAt: startIndex [

	| requests |
	requests := OrderedCollection new.
	startIndex to: testCases size do: [ :index |
		requests add: (self testRequestForTestCase: (testCases at: index)) ].
	^ requests asArray
]

{ #category : 'private' }
MCPToolRunTests >> testRequestsFromRequest: request [

	| normalized requests |
	requests := request objectCollectionArgumentNamed: 'tests'.
	normalized := OrderedCollection new.
	requests do: [ :each |
		| className testRequest testMethodName |
		(each respondsTo: #at:ifAbsent:) ifFalse: [
			Error signal:
				'tests must contain only objects with className and optional testMethodName.' ].
		className := request stringArgumentNamed: 'className' in: each.
		className ifNil: [
			Error signal: 'tests must contain only non-empty class names.' ].
		testMethodName := request
			                  stringArgumentNamed: 'testMethodName'
			                  in: each.
		testRequest := Dictionary new.
		testRequest at: #className put: className.
		testMethodName ifNotNil: [
			testRequest at: #testMethodName put: testMethodName ].
		normalized add: testRequest ].
	normalized ifEmpty: [
		Error signal: 'tests must contain at least one test request.' ].
	^ normalized asArray
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

{ #category : 'private - timeout' }
MCPToolRunTests >> timeoutMillisecondsFromRequest: request [

	^ (request
		   nonNegativeIntegerArgumentNamed: 'timeoutSeconds'
		   default: self defaultTimeoutSeconds) * 1000
]

{ #category : 'private' }
MCPToolRunTests >> unrunTestsFrom: validatedRequests startingAt: startIndex [

	| unrun |
	unrun := OrderedCollection new.
	startIndex to: validatedRequests size do: [ :index |
		unrun addAll: (self
				 testRequestsForTestCases:
				 (self testCasesForValidatedRequest: (validatedRequests at: index))
				 startingAt: 1) ].
	^ unrun asArray
]

{ #category : 'private' }
MCPToolRunTests >> validatedRequestsFrom: testRequests [

	^ testRequests collect: [ :each |
		  | className testClass testMethodName validated |
		  className := each at: #className.
		  testMethodName := each at: #testMethodName ifAbsent: [ nil ].
		  testClass := Smalltalk globals
			               at: className asSymbol
			               ifAbsent: [
			               MCPCommandError signalMissingClassNamed: className ].
		  testMethodName ifNotNil: [
			  testClass compiledMethodAt: testMethodName asSymbol ifAbsent: [
				  MCPCommandError
					  signalMissingMethodInClassName: className
					  classSide: false
					  selector: testMethodName ] ].
		  validated := Dictionary new.
		  validated at: #request put: each.
		  validated at: #class put: testClass.
		  validated yourself ]
]
