"
Run test packages, classes, or methods and return compact aggregate results.

MCPToolRunTestCoverage reuses the same selection and execution pipeline with coverage collection enabled.
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

{ #category : 'metadata' }
MCPToolRunTests class >> groupName [

	^ self testsGroupName
]

{ #category : 'metadata' }
MCPToolRunTests class >> toolName [

	^ 'test_run'
]

{ #category : 'metadata' }
MCPToolRunTests >> additionalKeywords [

	^ #( 'test' 'sunit' 'timeout' )
]

{ #category : 'metadata' }
MCPToolRunTests >> buildInputSchema [

	| timeoutProperty |
	timeoutProperty := self
		                   integerSchemaPropertyNamed: 'timeoutSeconds'
		                   description:
		                   'Timeout seconds; 0 returns immediately.'
		                   default: self defaultTimeoutSeconds.
	timeoutProperty minimum: 0.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties:
			  self testSelectionInputProperties , { timeoutProperty };
		  yourself
]

{ #category : 'metadata' }
MCPToolRunTests >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: self testRunDataProperties
		  required: #( 'runCount' 'passedCount' )
]

{ #category : 'private - execution' }
MCPToolRunTests >> commandForRequest: runTestsRequest [

	^ MCPRunTestsCommand tool: self request: runTestsRequest
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

	| methodLimitProperty property |
	methodLimitProperty := self
		                       integerSchemaPropertyNamed: 'methodLimit'
		                       description:
		                       'Maximum method entries per coverage list.'
		                       default: self defaultCoverageMethodLimit.
	methodLimitProperty minimum: 0.
	property := self
		            schemaPropertyNamed: 'coverage'
		            type: 'object'
		            description:
		            'Coverage options. Requires explicit method scope.'.
	property
		properties: self methodQueryScopeInputProperties , {
					(self
						 booleanSchemaPropertyNamed: 'includeCoveredMethods'
						 description: 'Include covered method details.'
						 default: false).
					methodLimitProperty };
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
		            'Coverage summary returned by test_coverage_run.'.
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

	^ 50
]

{ #category : 'metadata' }
MCPToolRunTests >> defaultExposure [

	^ 'static'
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultTimeoutSeconds [

	^ 90
]

{ #category : 'metadata' }
MCPToolRunTests >> description [

	^ 'Run test packages, classes, methods return compact aggregate results.'
]

{ #category : 'private' }
MCPToolRunTests >> errorResultForError: anError testNames: testNames [

	^ anError
		  mcpCommandErrorDo: [ :commandError |
				  self
					  errorResultText: commandError messageText
					  details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self
					  errorResultText:
					  (self failureMessageForTestNames: testNames error: toolError)
					  details: {
							  (#errorClass -> toolError class name).
							  (#message -> toolError messageText) } asDictionary ]
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
				  self errorResultForError: error testNames: (self
						   testNamesForErrorFromParsedRequest: runTestsRequest
						   rawRequest: request) ]
]

{ #category : 'private' }
MCPToolRunTests >> failureMessageForTestNames: testNames error: anError [

	^ String streamContents: [ :stream |
			  stream nextPutAll: 'Unable to run tests'.
			  testNames ifNotEmpty: [
					  stream
						  nextPutAll: ': ';
						  nextPutAll: (', ' join: testNames) ].
			  stream
				  nextPutAll: ' (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: anError messageText ]
]

{ #category : 'private - request' }
MCPToolRunTests >> parsedRequestFromToolRequest: request [

	^ MCPRunTestsRequest fromRequest: request tool: self operation: 'run'
]

{ #category : 'private - errors' }
MCPToolRunTests >> rawStringCollectionNamed: argumentName fromRequest: rawRequest [

	| value |
	value := rawRequest argumentNamed: argumentName ifAbsent: [ ^ #(  ) ].
	value isArray ifFalse: [ ^ #(  ) ].
	^ (value collect: [ :each | each asString ]) asArray
]

{ #category : 'private - errors' }
MCPToolRunTests >> rawTestNamesFromRequest: rawRequest [

	^ Array streamContents: [ :stream |
			  #( 'packages' 'classes' 'methods' ) do: [ :argumentName |
					  (self
						   rawStringCollectionNamed: argumentName
						   fromRequest: rawRequest) do: [ :each | stream nextPut: each ] ] ]
]

{ #category : 'private' }
MCPToolRunTests >> successSummaryForData: data [

	| coverage errorCount failureCount passedCount runCount skippedCount timedOut unrunCount |
	runCount := data at: #runCount.
	passedCount := data at: #passedCount.
	skippedCount := (data at: #skipped ifAbsent: [ #(  ) ]) size.
	failureCount := (data at: #failures ifAbsent: [ #(  ) ]) size.
	errorCount := (data at: #errors ifAbsent: [ #(  ) ]) size.
	timedOut := data at: #timedOut ifAbsent: [ false ].
	unrunCount := (data at: #unrunPackages ifAbsent: [ #(  ) ]) size
	              + (data at: #unrunClasses ifAbsent: [ #(  ) ]) size
	              + (data at: #unrunMethods ifAbsent: [ #(  ) ]) size.
	coverage := data at: #coverage ifAbsent: [ nil ].
	^ String streamContents: [ :stream |
			  timedOut ifTrue: [ stream nextPutAll: 'Timed out. ' ].
			  stream
				  nextPutAll: 'Ran ';
				  nextPutAll: runCount asString;
				  nextPutAll: ' tests (';
				  nextPutAll: passedCount asString;
				  nextPutAll: ' passed'.
			  skippedCount > 0 ifTrue: [
					  stream
						  nextPutAll: ', ';
						  nextPutAll: skippedCount asString;
						  nextPutAll: ' skipped' ].
			  stream nextPutAll: ').'.
			  failureCount + errorCount > 0 ifTrue: [
					  stream
						  space;
						  nextPutAll: failureCount asString;
						  nextPutAll: ' failures, ';
						  nextPutAll: errorCount asString;
						  nextPutAll: ' errors.' ].
			  unrunCount > 0 ifTrue: [
					  stream
						  space;
						  nextPutAll: unrunCount asString;
						  nextPutAll: ' selections left unrun.' ].
			  coverage ifNotNil: [ :coverageData |
					  stream
						  space;
						  nextPutAll: 'Coverage: ';
						  nextPutAll: (self coveragePercentageTextFor: coverageData);
						  nextPutAll: '%.' ] ]
]

{ #category : 'private - tests' }
MCPToolRunTests >> testIssueArraySchemaNamed: propertyName description: propertyDescription [

	^ (self
		   schemaPropertyNamed: propertyName
		   type: 'array'
		   description: propertyDescription)
		  items: self testIssueObjectSchema;
		  yourself
]

{ #category : 'private - tests' }
MCPToolRunTests >> testIssueObjectSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'test'
					   type: 'string'
					   description: 'Test reference.').
				  (self
					   schemaPropertyNamed: 'message'
					   type: 'string'
					   description: 'Failure or error message.').
				  (self
					   schemaPropertyNamed: 'errorClass'
					   type: 'string'
					   description: 'Error class.').
				  (self
					   stringArraySchemaNamed: 'parameters'
					   description: 'Parameterized test values.'
					   itemDescription: nil) };
		  required: #( 'test' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - errors' }
MCPToolRunTests >> testNamesForErrorFromParsedRequest: runTestsRequest rawRequest: rawRequest [

	runTestsRequest ifNotNil: [
		^ self testNamesFromRequests: runTestsRequest testRequests ].
	^ self rawTestNamesFromRequest: rawRequest
]

{ #category : 'private - errors' }
MCPToolRunTests >> testNamesFromRequests: testRequests [

	^ (testRequests collect: [ :each | each displayName ]) asArray
]

{ #category : 'private - tests' }
MCPToolRunTests >> testRunDataProperties [

	^ {
		  (self
			   integerSchemaPropertyNamed: 'runCount'
			   description: 'Tests run.').
		  (self
			   integerSchemaPropertyNamed: 'passedCount'
			   description: 'Tests passed.').
		  (self
			   stringArraySchemaNamed: 'skipped'
			   description: 'Skipped tests.'
			   itemDescription: nil).
		  (self
			   testIssueArraySchemaNamed: 'failures'
			   description: 'Failed tests.').
		  (self
			   testIssueArraySchemaNamed: 'errors'
			   description: 'Errored tests.').
		  (self
			   booleanSchemaPropertyNamed: 'timedOut'
			   description: 'Timeout stopped run.').
		  (self
			   stringArraySchemaNamed: 'unrunPackages'
			   description: 'Unrun test packages.'
			   itemDescription: nil).
		  (self
			   stringArraySchemaNamed: 'unrunClasses'
			   description: 'Unrun test classes.'
			   itemDescription: nil).
		  (self
			   stringArraySchemaNamed: 'unrunMethods'
			   description: 'Unrun test methods.'
			   itemDescription: nil) }
]

{ #category : 'private - tests' }
MCPToolRunTests >> testSelectionInputProperties [

	^ {
		  (self
			   stringArraySchemaNamed: 'packages'
			   description: 'Test packages run.'
			   itemDescription: nil).
		  (self
			   stringArraySchemaNamed: 'classes'
			   description: 'Test classes run.'
			   itemDescription: nil).
		  (self
			   stringArraySchemaNamed: 'methods'
			   description: 'Test methods as Class>>#selector.'
			   itemDescription: nil) }
]

{ #category : 'metadata' }
MCPToolRunTests >> title [

	^ 'Run Tests'
]
