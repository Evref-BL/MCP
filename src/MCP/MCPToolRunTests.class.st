"
Runs test classes or selected test methods and returns structured results.

The default operation is the testing bridge for the MCP server. The optional coverage operation runs the same test selection while measuring CoverageCollector method and node coverage for an explicit method scope.
"
Class {
	#name : 'MCPToolRunTests',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
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

{ #category : 'private - coverage schema' }
MCPToolRunTests >> coverageMethodArrayPropertyNamed: propertyName description: propertyDescription [

	^ (self
		   schemaPropertyNamed: propertyName
		   type: 'array'
		   description: propertyDescription)
		  items: self coverageMethodObjectSchema;
		  yourself
]

{ #category : 'private - coverage schema' }
MCPToolRunTests >> coverageMethodObjectSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description:
			  'A compiled method entry included in a coverage method list.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The method class name.').
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'The method selector.').
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description: 'Whether the method is on the class side.').
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description: 'The package that defines the method.').
				  (self
					   booleanSchemaPropertyNamed: 'isExtension'
					   description: 'Whether the method is an extension method.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description: 'The method protocol.') };
		  required:
			  #( 'className' 'selector' 'classSide' 'packageName' 'isExtension'
			     'protocol' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - coverage schema' }
MCPToolRunTests >> coverageOptionsObjectSchema [

	| property |
	property := self
		            schemaPropertyNamed: 'coverage'
		            type: 'object'
		            description:
		            'Coverage options for operation=coverage. At least one explicit method scope property is required when coverage is requested.'.
	property
		properties: self methodQueryScopeInputProperties , {
					(self
						 booleanSchemaPropertyNamed: 'includeCoveredMethods'
						 description:
							 'Whether to include capped coveredMethods details in the coverage result.'
						 default: false).
					(self
						 integerSchemaPropertyNamed: 'methodLimit'
						 description:
							 'Maximum number of method entries returned in each coverage method list. Use 0 for counts only.'
						 default: self defaultCoverageMethodLimit) };
		additionalProperties: false.
	^ property
]

{ #category : 'private - coverage' }
MCPToolRunTests >> coveragePercentageTextFor: coverageData [

	| percentage |
	percentage := coverageData at: #percentage ifAbsent: [ nil ].
	percentage ifNil: [ ^ 'n/a' ].
	^ percentage printShowingDecimalPlaces: 2
]

{ #category : 'private - coverage schema' }
MCPToolRunTests >> coverageResultObjectSchema [

	| property |
	property := self
		            schemaPropertyNamed: 'coverage'
		            type: 'object'
		            description:
		            'Coverage summary returned when operation=coverage.'.
	property
		properties: {
				(self
					 integerSchemaPropertyNamed: 'methodCount'
					 description: 'The number of instrumented methods.').
				(self
					 integerSchemaPropertyNamed: 'coveredMethodCount'
					 description:
						 'The number of instrumented methods that executed at least once.').
				(self
					 integerSchemaPropertyNamed: 'fullyCoveredMethodCount'
					 description:
						 'The number of executed methods whose sequence nodes all executed.').
				(self
					 integerSchemaPropertyNamed: 'uncoveredMethodCount'
					 description:
						 'The number of instrumented methods that did not execute.').
				(self
					 integerSchemaPropertyNamed: 'partiallyCoveredMethodCount'
					 description:
						 'The number of executed methods with at least one unexecuted sequence node.').
				(self
					 integerSchemaPropertyNamed: 'nodeCount'
					 description: 'The number of instrumented sequence nodes.').
				(self
					 integerSchemaPropertyNamed: 'coveredNodeCount'
					 description: 'The number of executed sequence nodes.').
				(self
					 schemaPropertyNamed: 'percentage'
					 type: #( 'number' 'null' )
					 description:
						 'Node coverage percentage, or null when no nodes were instrumented.').
				(self
					 coverageMethodArrayPropertyNamed: 'uncoveredMethods'
					 description:
						 'Capped list of instrumented methods that did not execute.').
				(self
					 coverageMethodArrayPropertyNamed: 'partiallyCoveredMethods'
					 description:
						 'Capped list of executed methods with at least one unexecuted sequence node.').
				(self
					 coverageMethodArrayPropertyNamed: 'coveredMethods'
					 description:
						 'Optional capped list of methods that executed at least once. Present only when includeCoveredMethods is true.').
				(self
					 booleanSchemaPropertyNamed: 'uncoveredMethodsTruncated'
					 description:
						 'Whether uncoveredMethods was capped by methodLimit.').
				(self
					 booleanSchemaPropertyNamed: 'partiallyCoveredMethodsTruncated'
					 description:
						 'Whether partiallyCoveredMethods was capped by methodLimit.').
				(self
					 booleanSchemaPropertyNamed: 'coveredMethodsTruncated'
					 description:
						 'Whether coveredMethods was capped by methodLimit. Present only when includeCoveredMethods is true.') };
		required:
			#( 'methodCount' 'coveredMethodCount' 'fullyCoveredMethodCount'
			   'uncoveredMethodCount' 'partiallyCoveredMethodCount'
			   'nodeCount' 'coveredNodeCount' 'percentage' 'uncoveredMethods'
			   'partiallyCoveredMethods' 'uncoveredMethodsTruncated'
			   'partiallyCoveredMethodsTruncated' );
		additionalProperties: false.
	^ property
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultCoverageMethodLimit [

	^ 200
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultDescription [

	^ 'Run test classes or individual test methods as a batch and return aggregated results. Use operation=coverage with an explicit coverage scope to collect method and node coverage for the same test run.'
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
					   stringEnumSchemaPropertyNamed: 'operation'
					   description:
					   'Test runner operation. run executes tests normally; coverage executes tests while measuring coverage for the explicit coverage scope.'
					   values: #( 'run' 'coverage' )
					   default: 'run').
				  self coverageOptionsObjectSchema.
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

	| coverageProperty resultsProperty unrunTestsProperty |
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
	coverageProperty := self coverageResultObjectSchema.
	^ self
		  standardOutputSchemaForDataProperties: {
				  resultsProperty.
				  coverageProperty.
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

{ #category : 'validating' }
MCPToolRunTests >> validateRequest: request [

	| operation |
	operation := request stringArgumentNamed: 'operation' default: 'run'.
	operation = 'coverage' ifTrue: [
		(request hasArgumentNamed: 'coverage') ifFalse: [
			MCPInvalidToolInput
				signalMissingRequiredArgumentNamed: 'coverage'
				forTool: self ] ]
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
	required := OrderedCollection withAll: #( 'className' 'runCount' ).
	includeMethodName ifTrue: [ required add: 'testMethodName' ].
	^ required asArray
]

{ #category : 'private' }
MCPToolRunTests >> successSummaryForData: data [

	| coverage failureLikeCount results runCount selectionCount selectionWord timedOut unrunCount |
	results := data at: #results.
	selectionCount := results size.
	selectionWord := selectionCount = 1
		                 ifTrue: [ 'test selection' ]
		                 ifFalse: [ 'test selections' ].
	runCount := results
		            inject: 0
		            into: [ :sum :each | sum + (each at: #runCount) ].
	failureLikeCount := results inject: 0 into: [ :sum :each |
		                    sum
		                    +
			                    ((each at: #issues ifAbsent: [ #(  ) ]) count: [
				                     :issue |
				                     #( 'failure' 'error' ) includes:
					                     (issue at: #kind) ]) asInteger ].
	timedOut := data at: #timedOut ifAbsent: [ false ].
	unrunCount := (data at: #unrunTests ifAbsent: [ #(  ) ]) size.
	coverage := data at: #coverage ifAbsent: [ nil ].
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
				  nextPutAll: ' test requests remain in unrunTests.' ].
		  coverage ifNotNil: [
			  stream
				  space;
				  nextPutAll: 'Coverage: ';
				  nextPutAll: (self coveragePercentageTextFor: coverage);
				  nextPutAll: ' over ';
				  nextPutAll: (coverage at: #methodCount) asString;
				  nextPutAll: ' methods; ';
				  nextPutAll: (coverage at: #uncoveredMethodCount) asString;
				  nextPutAll: ' uncovered, ';
				  nextPutAll: (coverage at: #partiallyCoveredMethodCount) asString;
				  nextPutAll: ' partially covered.' ] ]
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
					                  schemaPropertyNamed: 'testCaseName'
					                  type: 'string'
					                  description:
						                  'The concrete test case name, including parameter values when available.').
				                 (self
					                  stringArraySchemaNamed: 'parameters'
					                  description:
						                  'Parameter bindings for the concrete test case when the issue came from a parameterized test.'
					                  itemDescription:
						                  'A printed parameter binding, such as #encoding->''UTF-16''.').
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
