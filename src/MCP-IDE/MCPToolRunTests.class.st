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

{ #category : 'private - arguments' }
MCPToolRunTests >> addMethodSelectionsFrom: methodReferences to: aStream [
	"A method is read in every form method_get reads one, and its side is dropped: test_run reads Foo class as Foo. A case of a parameterized test is read as its method, so the name an answer gives it can be passed back. Every entry that names no method is refused, all in one refusal."

	| violations |
	violations := OrderedCollection new.
	methodReferences do: [ :each |
			(MCPMethodReference fromString: each)
				ifNil: [ violations add: (self violationForMethodReference: each) ]
				ifNotNil: [ :reference |
					aStream nextPut:
						(MCPTestSelectionSpec className: reference className testMethodName: (self testSelectorIn: reference selector)) ] ].
	violations ifNotEmpty: [ MCPInvalidToolInput signalForTool: self violations: violations ]
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

{ #category : 'private - arguments' }
MCPToolRunTests >> checkArguments: request [
	"What the schema cannot check: that the call names something to run, and that every method reference names a method."

	self testSelectionsFrom: request
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
	"The arguments are checked, then the selections they name run. An error raised before the arguments are checked names the tests as the caller wrote them."

	| checked |
	checked := false.
	^ self
		  executeRequest: request
		  do: [
				  self checkArguments: request.
				  checked := true.
				  self runTestsWith: request ]
		  onError: [ :error | self errorResultForError: error testNames: (self testNamesFor: request checked: checked) ]
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
	"failed <who>[: <message>][, at <statement> | , in <locations>][; <classes> was|were removed]; error <who> (<ErrorClass>)[: <message>][, in <locations>][; <classes> was|were removed][. <note>]; skipped <who>[: <reason>]. A message loses one trailing period when something follows it."

	| locations message note removedClasses statement |
	stream
		nextPut: Character lf;
		nextPutAll: aLabel;
		space;
		nextPutAll: (', ' join: ((self valueIn: entry at: #tests) ifNil: [ #(  ) ])).
	(self valueIn: entry at: #errorClass) ifNotNil: [ :errorClass | stream << ' (' << errorClass << ')' ].
	statement := self valueIn: entry at: #statement.
	locations := (self valueIn: entry at: #locations) ifNil: [ #(  ) ].
	note := self valueIn: entry at: #note.
	removedClasses := (self valueIn: entry at: #removedClasses) ifNil: [ #(  ) ].
	message := (self valueIn: entry at: #message) ifNil: [ self valueIn: entry at: #reason ].
	message ifNotNil: [
			stream
				nextPutAll: ': ';
				nextPutAll: ((statement isNil and: [ locations isEmpty and: [ removedClasses isEmpty and: [ note isNil ] ] ])
						 ifTrue: [ message ]
						 ifFalse: [ self textWithoutTrailingPeriod: message ]) ].
	statement ifNotNil: [ stream << ', at ' << statement ].
	locations ifNotEmpty: [ stream << ', in ' << (self joinedNames: locations) ].
	removedClasses ifNotEmpty: [
			stream
				nextPutAll: '; ';
				nextPutAll: (self joinedNames: removedClasses);
				nextPutAll: (removedClasses size = 1
						 ifTrue: [ ' was removed' ]
						 ifFalse: [ ' were removed' ]) ].
	note ifNotNil: [ stream << '. ' << note ]
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
	"The summary already says the counts, the tests that refer to removed classes, the selections that held no test and the timeout: 'Ran 2 tests (0 passed). 2 errors. Timed out after 90 seconds, during T>>#testC. 7 tests not run, listed below as test_run arguments.'"

	^ #( runCount passedCount failureCount errorCount skippedCount removedClassReferences withoutTests timedOut timeoutMilliseconds
	     interrupted notRunCount )
]

{ #category : 'private - execution' }
MCPToolRunTests >> operationFor: request [
	"The run the checked arguments ask for."

	^ MCPRunTestsCommand selections: (self testSelectionsFrom: request) timeoutMilliseconds: (self timeoutMillisecondsFrom: request)
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

{ #category : 'private - arguments' }
MCPToolRunTests >> refuseEmptySelectionIn: request [
	"An argument that names nothing once blank values are dropped is named, the first of packages, classes and methods. With none given at all, the call names nothing to run."

	#( 'packages' 'classes' 'methods' ) do: [ :argumentName |
			(request argumentNamed: argumentName ifAbsent: [ nil ]) ifNotNil: [
				MCPInvalidToolInput signalEmptyArgumentNamed: argumentName forTool: self ] ].
	MCPInvalidToolInput signalForTool: self violations: { (MCPJSONSchemaViolation
			 path: #(  )
			 keyword: #selectionRequired
			 message: 'Name at least one package, class or method to run.'
			 expected: nil
			 actual: nil) }
]

{ #category : 'private' }
MCPToolRunTests >> removedClassReferencesSentencesOn: stream for: entries [
	"<tests> refers to <class>, a removed class, so it ran the obsolete copy of <class>. <tests> refer to <classes>, removed classes, so they ran the obsolete copies of those classes. Create <every class> again with class_create, or change the test(s)."

	| classNames testCount |
	classNames := OrderedCollection new.
	testCount := 0.
	entries do: [ :entry |
			| classes tests |
			classes := self valueIn: entry at: #classes.
			tests := self valueIn: entry at: #tests.
			classes do: [ :each | classNames addIfNotPresent: each ].
			testCount := testCount + tests size.
			stream
				nextPutAll: (self joinedNames: tests);
				nextPutAll: (tests size = 1
						 ifTrue: [ ' refers to ' ]
						 ifFalse: [ ' refer to ' ]);
				nextPutAll: (self joinedNames: classes);
				nextPutAll: (classes size = 1
						 ifTrue: [ ', a removed class, so ' ]
						 ifFalse: [ ', removed classes, so ' ]);
				nextPutAll: (tests size = 1
						 ifTrue: [ 'it' ]
						 ifFalse: [ 'they' ]).
			classes size = 1
				ifTrue: [
						stream
							nextPutAll: ' ran the obsolete copy of ';
							nextPutAll: classes first ]
				ifFalse: [ stream nextPutAll: ' ran the obsolete copies of those classes' ].
			stream nextPutAll: '. ' ].
	stream
		nextPutAll: 'Create ';
		nextPutAll: (self joinedNames: classNames);
		nextPutAll: ' again with class_create, or change the ';
		nextPutAll: (testCount = 1
				 ifTrue: [ 'test.' ]
				 ifFalse: [ 'tests.' ])
]

{ #category : 'private - execution' }
MCPToolRunTests >> runTestsWith: request [
	"Runs the selections the checked arguments name, and says what they did."

	| data operation |
	operation := self operationFor: request.
	data := operation execute asDictionary.
	^ self successResultText: (self successSummaryForData: data) data: data warnings: (self warningsFor: operation)
]

{ #category : 'private' }
MCPToolRunTests >> successSummaryForData: data [
	"Ran <N test(s)> (<P> passed).[ <F failure(s)>, <E error(s)>.][ <S> skipped.][ <removed class sentences>][ <selection sentences>][ <timeout sentence>][ Coverage[ so far]: <p>%.] The opening stays on every answer that runs, a timeout's included, since graders read it."

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
			  (self valueIn: data at: #removedClassReferences) ifNotNil: [ :entries |
					  stream space.
					  self removedClassReferencesSentencesOn: stream for: entries ].
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
MCPToolRunTests >> testNamesFor: request checked: aBoolean [
	"The tests an error names: as the selections read them once the arguments are checked, else as the caller wrote them."

	aBoolean ifTrue: [ ^ (self testSelectionsFrom: request) collect: [ :each | each displayName ] as: Array ].
	^ self rawTestNamesFromRequest: request
]

{ #category : 'private - tests' }
MCPToolRunTests >> testSelectionInputProperties [

	^ {
		  (self stringArraySchemaNamed: 'packages' description: 'Run every test class in these packages.' itemDescription: nil).
		  (self stringArraySchemaNamed: 'classes' description: 'Run these test classes.' itemDescription: nil).
		  (self stringArraySchemaNamed: 'methods' description: 'Run these test methods, as Class>>selector.' itemDescription: nil) }
]

{ #category : 'private - arguments' }
MCPToolRunTests >> testSelectionsFrom: request [
	"Every selection, in the order packages, classes, methods. The refusals answer like the schema's."

	| classNames methodReferences packageNames |
	packageNames := request uniqueStringCollectionArgumentNamed: 'packages'.
	classNames := request uniqueStringCollectionArgumentNamed: 'classes'.
	methodReferences := request uniqueStringCollectionArgumentNamed: 'methods'.
	(packageNames isEmpty and: [ classNames isEmpty and: [ methodReferences isEmpty ] ]) ifTrue: [
		self refuseEmptySelectionIn: request ].
	^ Array streamContents: [ :stream |
			  packageNames do: [ :each | stream nextPut: (MCPTestSelectionSpec packageName: each) ].
			  classNames do: [ :each | stream nextPut: (MCPTestSelectionSpec className: each) ].
			  self addMethodSelectionsFrom: methodReferences to: stream ]
]

{ #category : 'private - arguments' }
MCPToolRunTests >> testSelectorIn: aSelectorText [
	"The selector of a test as an answer names it. A case of a parameterized test is named Class>>#selector with its parameters, and a test selector is unary, so what follows the selector's first ' with ' is the case's parameters, and passing that name back runs every case of the method."

	| index |
	index := aSelectorText indexOfSubCollection: ' with '.
	index isZero ifTrue: [ ^ aSelectorText ].
	^ (aSelectorText first: index - 1) trimBoth
]

{ #category : 'private - results' }
MCPToolRunTests >> textWithoutTrailingPeriod: aString [
	"One period, so that 'Got 1 instead of 2.' reads on into ', at ...' and an ellipsis keeps two."

	^ (aString isNotEmpty and: [ aString last = $. ])
		  ifTrue: [ aString allButLast ]
		  ifFalse: [ aString ]
]

{ #category : 'private - arguments' }
MCPToolRunTests >> timeoutMillisecondsFrom: request [

	^ (request integerArgumentNamed: 'timeoutSeconds') * 1000
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

{ #category : 'private - arguments' }
MCPToolRunTests >> violationForMethodReference: aString [

	^ MCPJSONSchemaViolation
		  path: #( 'methods' )
		  keyword: #methodReference
		  message: aString , ' is not a method reference; write it as Class>>#selector.'
		  expected: nil
		  actual: aString
]

{ #category : 'private - results' }
MCPToolRunTests >> warningsFor: anOperation [
	"test_run refuses a selection that names nothing before anything runs, so a call that ran has nothing to warn of."

	^ #(  )
]

{ #category : 'private' }
MCPToolRunTests >> withoutTestsSentenceOn: stream for: entry [
	"ZooKeeperTest has no tests."

	stream
		nextPutAll: (self valueIn: entry at: #selection);
		space;
		nextPutAll: (self valueIn: entry at: #reason);
		nextPut: $.
]
