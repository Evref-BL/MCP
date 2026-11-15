"
Run test packages, classes, or methods and return compact aggregate results.

MCPToolRunTestCoverage reuses the same selection and execution pipeline with coverage collection enabled.
"
Class {
	#name : 'MCPToolRunTests',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self testSelectionInputProperties , { self timeoutSecondsProperty };
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
	"Each issue is read as a line naming the tests it hit, why and where, failures first, then errors, then skips; what a timeout left to run and coverage follow as records."

	| rest |
	#( #failures 'failed' #errors 'error' #skipped 'skipped' ) pairsDo: [ :key :label |
		(self valueIn: data at: key) ifNotNil: [ :entries |
			entries do: [ :entry | self issueLineOn: stream for: entry labelled: label ] ] ].
	rest := data copy.
	#( failures errors skipped ) do: [ :key |
			rest removeKey: key ifAbsent: [ nil ].
			rest removeKey: key asString ifAbsent: [ nil ] ].
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

	^ 'Run SUnit tests by package, class or Class>>selector, and report failures and errors.'
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

{ #category : 'private' }
MCPToolRunTests >> issueCountsOn: stream for: data [
	"1 failure, 1 error. A count of none is left out, and so is the sentence when both are."

	| parts |
	parts := OrderedCollection new.
	#( #failureCount 'failure' #errorCount 'error' ) pairsDo: [ :key :noun |
		(self valueIn: data at: key) ifNotNil: [ :count | count isZero ifFalse: [ parts add: (self textForCount: count noun: noun) ] ] ].
	parts ifEmpty: [ ^ self ].
	stream
		space;
		nextPutAll: (', ' join: parts);
		nextPut: $.
]

{ #category : 'private - results' }
MCPToolRunTests >> issueLineOn: stream for: entry labelled: aLabel [
	"failed <who>[: <message>][, at <statement> | , in <locations>]; error <who> (<ErrorClass>)[: <message>][, in <locations>]; skipped <who>[: <reason>]. A message loses one trailing period when a place follows it."

	| locations message statement |
	stream
		nextPut: Character lf;
		nextPutAll: aLabel;
		space;
		nextPutAll: (', ' join: ((self valueIn: entry at: #tests) ifNil: [ #(  ) ])).
	(self valueIn: entry at: #errorClass) ifNotNil: [ :errorClass | stream << ' (' << errorClass << ')' ].
	statement := self valueIn: entry at: #statement.
	locations := (self valueIn: entry at: #locations) ifNil: [ #(  ) ].
	message := (self valueIn: entry at: #message) ifNil: [ self valueIn: entry at: #reason ].
	message ifNotNil: [
			stream
				nextPutAll: ': ';
				nextPutAll: ((statement isNil and: [ locations isEmpty ])
						 ifTrue: [ message ]
						 ifFalse: [ self textWithoutTrailingPeriod: message ]) ].
	statement ifNotNil: [ stream << ', at ' << statement ].
	locations ifNotEmpty: [ stream << ', in ' << (self joinedNames: locations) ]
]

{ #category : 'private - results' }
MCPToolRunTests >> joinedNames: someStrings [
	"A, A and B, A, B and C."

	^ String streamContents: [ :stream |
			  someStrings withIndexDo: [ :each :index |
					  index > 1 ifTrue: [
							  stream nextPutAll: (index = someStrings size
									   ifTrue: [ ' and ' ]
									   ifFalse: [ ', ' ]) ].
					  stream nextPutAll: each ] ]
]

{ #category : 'private - results' }
MCPToolRunTests >> keysStatedInSummary [
	"The summary already says the counts, the selections that held no test and the timeout: 'Ran 2 tests (0 passed). 2 errors. Timed out after 90 seconds, during T>>#testC. 7 tests not run, listed below as test_run arguments.'"

	^ #( runCount passedCount failureCount errorCount skippedCount withoutTests timedOut timeoutMilliseconds interrupted notRunCount )
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
	^ value collect: [ :each | each asString ] as: Array
]

{ #category : 'private - errors' }
MCPToolRunTests >> rawTestNamesFromRequest: rawRequest [

	^ Array streamContents: [ :stream |
			  #( 'packages' 'classes' 'methods' ) do: [ :argumentName |
				  (self rawStringCollectionNamed: argumentName fromRequest: rawRequest) do: [ :each | stream nextPut: each ] ] ]
]

{ #category : 'private' }
MCPToolRunTests >> successSummaryForData: data [
	"Ran <N test(s)> (<P> passed).[ <F failure(s)>, <E error(s)>.][ <S> skipped.][ <selection sentences>][ <timeout sentence>][ Coverage[ so far]: <p>%.] The opening stays on every answer that runs, a timeout's included, since graders read it."

	| timedOut |
	timedOut := (self valueIn: data at: #timedOut) = true.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Ran ';
				  nextPutAll: (self textForCount: (self valueIn: data at: #runCount) noun: 'test');
				  nextPutAll: ' (';
				  print: (self valueIn: data at: #passedCount);
				  nextPutAll: ' passed).'.
			  self issueCountsOn: stream for: data.
			  (self valueIn: data at: #skippedCount) ifNotNil: [ :count |
					  stream
						  space;
						  print: count;
						  nextPutAll: ' skipped.' ].
			  ((self valueIn: data at: #withoutTests) ifNil: [ #(  ) ]) do: [ :entry |
					  stream space.
					  self withoutTestsSentenceOn: stream for: entry ].
			  timedOut ifTrue: [
					  stream space.
					  self timeoutSentenceOn: stream for: data ].
			  (self valueIn: data at: #coverage) ifNotNil: [ :coverageData |
					  stream
						  nextPutAll: (timedOut
								   ifTrue: [ ' Coverage so far: ' ]
								   ifFalse: [ ' Coverage: ' ]);
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

	^ testRequests collect: [ :each | each displayName ] as: Array
]

{ #category : 'private - tests' }
MCPToolRunTests >> testSelectionInputProperties [

	^ {
		  (self stringArraySchemaNamed: 'packages' description: 'Run every test class in these packages.' itemDescription: nil).
		  (self stringArraySchemaNamed: 'classes' description: 'Run these test classes.' itemDescription: nil).
		  (self stringArraySchemaNamed: 'methods' description: 'Run these test methods, as Class>>selector.' itemDescription: nil) }
]

{ #category : 'private' }
MCPToolRunTests >> textForPackages: someNames of: aCount [
	"A, B and C, or past the names said, A, B, C and 2 other packages."

	aCount > someNames size ifFalse: [ ^ self joinedNames: someNames ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (', ' join: someNames);
				  nextPutAll: ' and ';
				  nextPutAll: (self textForCount: aCount - someNames size noun: 'other package') ]
]

{ #category : 'private - results' }
MCPToolRunTests >> textWithoutTrailingPeriod: aString [
	"One period, so that 'Got 1 instead of 2.' reads on into ', at ...' and an ellipsis keeps two."

	^ (aString isNotEmpty and: [ aString last = $. ])
		  ifTrue: [ aString allButLast ]
		  ifFalse: [ aString ]
]

{ #category : 'private - schema' }
MCPToolRunTests >> timeoutSecondsProperty [
	"test_run and test_coverage_run give up alike, so they say it alike."

	| property |
	property := self
		            integerSchemaPropertyNamed: 'timeoutSeconds'
		            description: 'Give up after this many seconds and report what ran by then. 0 answers at once.'
		            default: self defaultTimeoutSeconds.
	property minimum: 0.
	^ property
]

{ #category : 'private' }
MCPToolRunTests >> timeoutSentenceOn: stream for: data [
	"Timed out after <duration>[, during <test>[, in <location>]]. <M test(s)> not run, listed below as test_run arguments. A timeout of 0 runs nothing, and says so."

	| milliseconds notRun |
	milliseconds := self valueIn: data at: #timeoutMilliseconds.
	notRun := String streamContents: [ :notRunStream |
			          notRunStream
				          nextPutAll: (self textForCount: ((self valueIn: data at: #notRunCount) ifNil: [ 0 ]) noun: 'test');
				          nextPutAll: ' not run, listed below as ';
				          nextPutAll: self name;
				          nextPutAll: ' arguments.' ].
	milliseconds = 0 ifTrue: [
			stream
				nextPutAll: 'timeoutSeconds is 0, so nothing ran; ';
				nextPutAll: notRun.
			^ self ].
	stream nextPutAll: 'Timed out'.
	milliseconds ifNotNil: [
			stream
				nextPutAll: ' after ';
				nextPutAll: (MCPStructuredTestResult textForDuration: (Duration milliSeconds: milliseconds)) ].
	(self valueIn: data at: #interrupted) ifNotNil: [ :interrupted |
			stream
				nextPutAll: ', during ';
				nextPutAll: (self valueIn: interrupted at: #test).
			(self valueIn: interrupted at: #location) ifNotNil: [ :location |
					stream
						nextPutAll: ', in ';
						nextPutAll: location ] ].
	stream
		nextPutAll: '. ';
		nextPutAll: notRun
]

{ #category : 'metadata' }
MCPToolRunTests >> title [

	^ 'Run Tests'
]

{ #category : 'private' }
MCPToolRunTests >> withoutTestsSentenceOn: stream for: entry [
	"Eval-Text holds no test class; test classes in Eval-Text-Tests refer to its classes. EvalLedgerTest has no tests."

	| testPackages |
	stream
		nextPutAll: (self valueIn: entry at: #selection);
		space;
		nextPutAll: (self valueIn: entry at: #reason).
	testPackages := (self valueIn: entry at: #testPackages) ifNil: [ #(  ) ].
	testPackages ifNotEmpty: [
			stream
				nextPutAll: '; test classes in ';
				nextPutAll:
					(self textForPackages: testPackages of: ((self valueIn: entry at: #testPackageCount) ifNil: [ testPackages size ]));
				nextPutAll: ' refer to its classes' ].
	stream nextPut: $.
]
