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
		                   description: 'Give up after this many seconds and report what ran by then. 0 answers at once.'
		                   default: self defaultTimeoutSeconds.
	timeoutProperty minimum: 0.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self testSelectionInputProperties , { timeoutProperty };
		  yourself
]

{ #category : 'private - execution' }
MCPToolRunTests >> commandForRequest: runTestsRequest [

	^ MCPRunTestsCommand tool: self request: runTestsRequest
]

{ #category : 'private - coverage schema' }
MCPToolRunTests >> coverageMethodArrayPropertyNamed: propertyName description: propertyDescription [

	^ (self schemaPropertyNamed: propertyName type: 'array' description: propertyDescription)
		  items: self coverageMethodObjectSchema;
		  yourself
]

{ #category : 'private - coverage schema' }
MCPToolRunTests >> coverageMethodObjectSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'A compiled method entry included in a coverage method list.';
		  properties: {
				  (self schemaPropertyNamed: 'class' type: 'string' description: 'The method class name.').
				  (self schemaPropertyNamed: 'selector' type: 'string' description: 'The method selector.').
				  (self targetSideSchemaPropertyDescribedAs: 'Which side the method is on; absent means instance.').
				  (self schemaPropertyNamed: 'package' type: 'string' description: 'The package that defines the method.').
				  (self booleanSchemaPropertyNamed: 'isExtension' description: 'Whether the method is an extension method.').
				  (self schemaPropertyNamed: 'protocol' type: 'string' description: 'The method protocol.') };
		  required: #( 'class' 'selector' 'package' 'isExtension' 'protocol' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - coverage schema' }
MCPToolRunTests >> coverageOptionsObjectSchema [

	| methodLimitProperty property |
	methodLimitProperty := self
		                       integerSchemaPropertyNamed: 'methodLimit'
		                       description: 'Most method entries to list per coverage list, so a wide scope does not fill the answer.'
		                       default: self defaultCoverageMethodLimit.
	methodLimitProperty minimum: 0.
	property := self
		            schemaPropertyNamed: 'coverage'
		            type: 'object'
		            description:
		            'Which methods to measure coverage of. Its scope is required: coverage is reported for the methods that scope selects, not for whatever the tests happen to reach.'.
	property
		properties: self methodQueryScopeInputProperties , {
					(self
						 booleanSchemaPropertyNamed: 'includeCoveredMethods'
						 description: 'Also list the methods that were executed, not only those that were not.'
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

{ #category : 'private - results' }
MCPToolRunTests >> dataTextOn: stream for: data [
	"A failed test is read as a line naming it and why, not as a record."

	| rest |
	#( failures errors ) do: [ :key |
			(data at: key ifAbsent: [ #(  ) ]) do: [ :entry |
					stream
						nextPut: Character lf;
						nextPutAll: (key = #failures
								 ifTrue: [ 'failed ' ]
								 ifFalse: [ 'error ' ]);
						nextPutAll: (entry at: #test ifAbsent: [ '?' ]).
					entry at: #errorClass ifPresent: [ :errorClass |
							stream
								nextPutAll: ' (';
								nextPutAll: errorClass;
								nextPut: $) ].
					entry at: #message ifPresent: [ :message |
							stream
								nextPutAll: ': ';
								nextPutAll: message ] ] ].
	rest := data copy.
	#( failures errors ) do: [ :key | rest removeKey: key ifAbsent: [ nil ] ].
	super dataTextOn: stream for: rest
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

	^ 'Run tests and return a compact summary with the failures and errors. Name test packages, test classes or individual test methods; at least one of the three is required.'
]

{ #category : 'private' }
MCPToolRunTests >> errorResultForError: anError testNames: testNames [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self errorResultText: (self failureMessageForTestNames: testNames error: toolError) details: {
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
				  self successResultText: (self successSummaryForData: data) data: data ]
		  onError: [ :error :runTestsRequest |
			  self errorResultForError: error testNames: (self testNamesForErrorFromParsedRequest: runTestsRequest rawRequest: request) ]
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

{ #category : 'private - results' }
MCPToolRunTests >> keysStatedInSummary [
	"The summary already reads 'Ran 731 tests (728 passed). 3 failures, 0 errors.'"

	^ #( runCount passedCount failureCount errorCount skippedCount )
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
				  (self rawStringCollectionNamed: argumentName fromRequest: rawRequest) do: [ :each | stream nextPut: each ] ] ]
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
	unrunCount := (data at: #unrunPackages ifAbsent: [ #(  ) ]) size + (data at: #unrunClasses ifAbsent: [ #(  ) ]) size
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

{ #category : 'private - errors' }
MCPToolRunTests >> testNamesForErrorFromParsedRequest: runTestsRequest rawRequest: rawRequest [

	runTestsRequest ifNotNil: [ ^ self testNamesFromRequests: runTestsRequest testRequests ].
	^ self rawTestNamesFromRequest: rawRequest
]

{ #category : 'private - errors' }
MCPToolRunTests >> testNamesFromRequests: testRequests [

	^ (testRequests collect: [ :each | each displayName ]) asArray
]

{ #category : 'private - tests' }
MCPToolRunTests >> testSelectionInputProperties [

	^ {
		  (self stringArraySchemaNamed: 'packages' description: 'Run every test class in these packages.' itemDescription: nil).
		  (self stringArraySchemaNamed: 'classes' description: 'Run these test classes.' itemDescription: nil).
		  (self stringArraySchemaNamed: 'methods' description: 'Run these test methods, as Class>>#selector.' itemDescription: nil) }
]

{ #category : 'metadata' }
MCPToolRunTests >> title [

	^ 'Run Tests'
]
