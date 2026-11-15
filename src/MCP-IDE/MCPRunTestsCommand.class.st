"
Command that validates and runs parsed test_run selections.

It resolves MCPTestRunRequest objects to MCPValidatedTestRunRequest objects, executes them, and returns MCPRunTestsResult DTOs.
"
Class {
	#name : 'MCPRunTestsCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'private - not run' }
MCPRunTestsCommand >> addNotRunOf: validatedRequests startingAt: startIndex seenTestCaseNames: seenTestCaseNames to: requests [
	"The selections after the one a timeout fell in, each whole when none of its cases was lost to an earlier selection, else its cases as methods. Answers how many tests they hold."

	| count |
	count := 0.
	startIndex to: validatedRequests size do: [ :index |
			| testCases uniqueTestCases validatedRequest |
			validatedRequest := validatedRequests at: index.
			testCases := self testCasesForValidatedRequest: validatedRequest.
			uniqueTestCases := self uniqueTestCasesFrom: testCases seenTestCaseNames: seenTestCaseNames.
			count := count + uniqueTestCases size.
			uniqueTestCases ifNotEmpty: [
					requests addAll: (uniqueTestCases size = testCases size
							 ifTrue: [ { validatedRequest testRunRequest } ]
							 ifFalse: [ self methodRequestsForTestCases: uniqueTestCases ]) ] ].
	^ count
]

{ #category : 'private' }
MCPRunTestsCommand >> addTestCasesFrom: aTestOrSuite to: testCases [

	aTestOrSuite mcpAddTestCasesTo: testCases using: self
]

{ #category : 'private' }
MCPRunTestsCommand >> aggregateDataForResults: resultEntries timedOut: timedOut unrunTests: unrunTests [

	^ MCPRunTestsResult results: resultEntries timedOut: timedOut unrunTests: unrunTests
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> coverableMethodsForCoverageRequest: aCoverageRequest [

	^ (aCoverageRequest scopeQuery methods reject: [ :method | self shouldIgnoreMethodForCoverage: method ]) asArray
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> coverageCollectorForMethods: methods [

	| collector |
	collector := self coverageCollectorClass new.
	collector methods: methods.
	^ collector
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> deadlineForTimeoutMilliseconds: timeoutMilliseconds [

	^ Time millisecondClockValue + timeoutMilliseconds
]

{ #category : 'executing' }
MCPRunTestsCommand >> execute [

	| deadline validatedRequests |
	validatedRequests := self validatedRequestsFrom: request testRequests.
	deadline := self deadlineForTimeoutMilliseconds: request timeoutMilliseconds.
	^ request isCoverageOperation
		  ifTrue: [ self runCoverageForValidatedRequests: validatedRequests deadline: deadline ]
		  ifFalse: [ self runValidatedRequests: validatedRequests deadline: deadline ]
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> hasAllSequenceNodesCoveredIn: aCompiledMethod [

	aCompiledMethod ast nodesDo: [ :node | node isSequence ifTrue: [ node hasBeenExecuted ifFalse: [ ^ false ] ] ].
	^ true
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> hasTimedOutAt: deadline [

	^ (self millisecondsRemainingUntil: deadline) <= 0
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> locationOf: aContext in: aTestCase [
	"Where the test was running when the timeout fell, unless that was the test method."

	^ MCPStructuredTestResult locationOf: aContext in: aTestCase
]

{ #category : 'private - not run' }
MCPRunTestsCommand >> methodRequestsForTestCases: someTestCases [
	"One method each, in order, so that the cases of a parameterized test name their method once."

	| names |
	names := Set new.
	^ Array streamContents: [ :stream |
			  someTestCases do: [ :each |
					  | methodRequest |
					  methodRequest := self testRequestForTestCase: each.
					  (names includes: methodRequest displayName) ifFalse: [
							  names add: methodRequest displayName.
							  stream nextPut: methodRequest ] ] ]
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> millisecondsRemainingUntil: deadline [

	^ 0 max: deadline - Time millisecondClockValue
]

{ #category : 'private - not run' }
MCPRunTestsCommand >> notRunRequestsForValidatedRequest: validatedRequest testCases: testCases uniqueTestCases: uniqueTestCases startingAt: startIndex [
	"What is left of the selection a timeout fell in, as test_run arguments: the selection itself when none of its cases ran or was lost to an earlier selection; else, for a package, each class from the interrupted one on, whole when none of its cases ran or was lost, else its cases left as methods; for a class or a method, its cases left as methods."

	| left |
	(startIndex = 1 and: [ uniqueTestCases size = testCases size ]) ifTrue: [ ^ { validatedRequest testRunRequest } ].
	left := uniqueTestCases allButFirst: startIndex - 1.
	validatedRequest isPackageRequest ifFalse: [ ^ self methodRequestsForTestCases: left ].
	^ Array streamContents: [ :stream |
			  (self testCasesByClassIn: left) do: [ :each |
					  (testCases count: [ :testCase | testCase class == each key ]) = each value size
						  ifTrue: [ stream nextPut: (MCPTestRunRequest className: each key name asString) ]
						  ifFalse: [ stream nextPutAll: (self methodRequestsForTestCases: each value) ] ] ]
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> partiallyCoveredMethodsFromCoverageResult: coverageResult [

	^ (coverageResult methods select: [ :method | (self hasAllSequenceNodesCoveredIn: method) not ]) asArray
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> refusalOfSelection: validatedRequest [
	"Nil for a selection that holds tests, or a package; else its sentence and its entry. A test class whose suite holds no case of the method is refused, and so is any class that is not a test class."

	| entry selection testClass |
	validatedRequest isPackageRequest ifTrue: [ ^ nil ].
	testClass := validatedRequest testClass.
	selection := self selectionTextOf: validatedRequest.
	entry := Dictionary new.
	entry at: #selection put: selection.
	entry at: #class put: testClass name asString.
	testClass isTestCase ifFalse: [
			^ (String streamContents: [ :stream |
					   validatedRequest hasTestMethod ifTrue: [ stream << selection << ' is not a test: ' ].
					   stream << testClass name << ' is not a test class.' ]) -> entry ].
	validatedRequest hasTestMethod ifFalse: [ ^ nil ].
	(self testCasesForValidatedRequest: validatedRequest) ifNotEmpty: [ ^ nil ].
	^ (self textForMethod: selection notATestOf: testClass name) -> entry
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> refuseSelectionsThatAreNotTests: validatedRequests [
	"One sentence per selection that is no test, in selection order, all in one refusal."

	| refusals |
	refusals := (validatedRequests collect: [ :each | self refusalOfSelection: each ]) reject: [ :each | each isNil ].
	refusals ifEmpty: [ ^ self ].
	MCPCommandError
		signalErrorCode: ((validatedRequests anySatisfy: [ :each | each isPackageRequest not and: [ each testClass isTestCase not ] ])
				 ifTrue: [ #NotATestClass ]
				 ifFalse: [ #NotATest ])
		message: (' ' join: (refusals collect: [ :each | each key ]))
		details: { (#notTests -> (refusals collect: [ :each | each value ] as: Array)) } asDictionary
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> resolvedRequestFor: aTestRequest [
	"A method is looked up as its class answers it, so a test the class inherits is found."

	| testClass |
	aTestRequest isPackageRequest ifTrue: [
			MCPImageLookup packageNamed: aTestRequest packageName.
			^ MCPValidatedTestRunRequest request: aTestRequest testClass: nil ].
	testClass := MCPImageLookup classNamed: aTestRequest className.
	aTestRequest testMethodName ifNotNil: [ :selector |
		(testClass lookupSelector: selector asSymbol) ifNil: [ MCPCommandError signalMissingMethod: selector in: testClass ] ].
	^ MCPValidatedTestRunRequest request: aTestRequest testClass: testClass
]

{ #category : 'private' }
MCPRunTestsCommand >> resultForResults: resultEntries interruption: anOutcomeOrNil notRun: testRequests notRunCount: aCount [
	"After a timeout. One that leaves no test unrun is not reported."

	aCount isZero ifTrue: [ ^ self aggregateDataForResults: resultEntries timedOut: false unrunTests: #(  ) ].
	^ (self aggregateDataForResults: resultEntries timedOut: true unrunTests: testRequests)
		  interruption: anOutcomeOrNil;
		  notRunCount: aCount;
		  timeoutMilliseconds: request timeoutMilliseconds;
		  yourself
]

{ #category : 'private' }
MCPRunTestsCommand >> resultForValidatedRequest: validatedRequest deadline: deadline seenTestCaseNames: seenTestCaseNames [
	"Each test runs into a result of its own, so that SUnit counts it once however many exceptions it raised. The first test the deadline stops ends the selection, and what is left of it is listed to run next."

	| index info outcome outcomes stopped testCases uniqueTestCases |
	testCases := self testCasesForValidatedRequest: validatedRequest.
	uniqueTestCases := self uniqueTestCasesFrom: testCases seenTestCaseNames: seenTestCaseNames.
	outcomes := OrderedCollection new.
	index := 0.
	[ stopped isNil and: [ index < uniqueTestCases size ] ] whileTrue: [
			index := index + 1.
			outcome := self runTestCase: (uniqueTestCases at: index) into: MCPStructuredTestResult new deadline: deadline.
			outcome isFinished
				ifTrue: [ outcomes add: outcome ]
				ifFalse: [ stopped := outcome ] ].
	info := MCPTestRunInfo validatedRequest: validatedRequest selectedTestCount: uniqueTestCases size outcomes: outcomes.
	stopped ifNil: [ ^ MCPTestRunResult resultInfo: info timedOut: false unrunTestRequests: #(  ) ].
	^ (MCPTestRunResult resultInfo: info timedOut: true unrunTestRequests: (self
				    notRunRequestsForValidatedRequest: validatedRequest
				    testCases: testCases
				    uniqueTestCases: uniqueTestCases
				    startingAt: index))
		  interruption: (stopped isInterrupted ifTrue: [ stopped ]);
		  notRunCount: uniqueTestCases size - index + 1;
		  yourself
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> runCoverageForValidatedRequests: validatedRequests deadline: deadline [

	| collector coverageRequest coverageResult methods partialMethods runResult |
	coverageRequest := request coverageRequest.
	methods := self coverableMethodsForCoverageRequest: coverageRequest.
	collector := self coverageCollectorForMethods: methods.
	[
		collector installOn: [
				collector reset.
				runResult := self runValidatedRequests: validatedRequests deadline: deadline.
				"Collect before resetting annotations so partial node coverage remains observable."
				collector remapMethods.
				coverageResult := collector basicCollectResult.
				partialMethods := self partiallyCoveredMethodsFromCoverageResult: coverageResult ] ] ensure: [ collector reset ].
	runResult coverage: (MCPTestCoverageResult
			 coverageResult: coverageResult
			 includeCoveredMethods: coverageRequest includeCoveredMethods
			 methodLimit: coverageRequest methodLimit
			 partiallyCoveredMethods: partialMethods).
	^ runResult
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> runTestCase: aTestCase into: aResult deadline: deadline [
	"The test's outcome. When the deadline falls while it runs, an outcome that says it was interrupted and where it was, its result discarded since it never finished; when the deadline has already passed, one that says it never started. The flag is set before the timeout unwinds the test, so a time limit SUnit enforces during the unwinding cannot undo it."

	| interrupted location remaining timed |
	remaining := self millisecondsRemainingUntil: deadline.
	remaining <= 0 ifTrue: [ ^ MCPTestOutcome notStarted: aTestCase ].
	interrupted := false.
	timed := [
		         [ aTestCase run: aResult ]
			         on: TimedOut
			         do: [ :timeout |
					         timeout tag == timed ifTrue: [ location := self locationOf: timeout signalerContext in: aTestCase ].
					         timeout pass ] ].
	timed valueWithinMilliseconds: remaining onTimeout: [
			interrupted := true.
			self shortenTimeLimitOf: aTestCase ].
	^ interrupted
		  ifTrue: [ MCPTestOutcome interrupted: aTestCase location: location ]
		  ifFalse: [ MCPTestOutcome testCase: aTestCase result: aResult ]
]

{ #category : 'private' }
MCPRunTestsCommand >> runValidatedRequests: validatedRequests deadline: deadline [
	"Runs the selections in order until the deadline, then lists what was not run. The selections that hold no test are said whatever the deadline, since running cannot change that."

	^ (self runValidatedRequestsUntil: deadline from: validatedRequests)
		  withoutTests: (self withoutTestsIn: validatedRequests);
		  yourself
]

{ #category : 'private' }
MCPRunTestsCommand >> runValidatedRequestsUntil: deadline from: validatedRequests [
	"Runs the selections in order until the deadline, then lists what was not run."

	| notRun notRunCount resultEntries seenTestCaseNames selectionResult |
	resultEntries := OrderedCollection new.
	seenTestCaseNames := Set new.
	1 to: validatedRequests size do: [ :index |
			(self hasTimedOutAt: deadline) ifTrue: [
					notRun := OrderedCollection new.
					notRunCount := self
						               addNotRunOf: validatedRequests
						               startingAt: index
						               seenTestCaseNames: seenTestCaseNames
						               to: notRun.
					^ self
						  resultForResults: resultEntries
						  interruption: nil
						  notRun: notRun
						  notRunCount: notRunCount ].
			selectionResult := self
				                   resultForValidatedRequest: (validatedRequests at: index)
				                   deadline: deadline
				                   seenTestCaseNames: seenTestCaseNames.
			resultEntries add: selectionResult resultInfo.
			selectionResult timedOut ifTrue: [
					notRun := OrderedCollection withAll: selectionResult unrunTestRequests.
					notRunCount := selectionResult notRunCount + (self
						                addNotRunOf: validatedRequests
						                startingAt: index + 1
						                seenTestCaseNames: seenTestCaseNames
						                to: notRun).
					^ self
						  resultForResults: resultEntries
						  interruption: selectionResult interruption
						  notRun: notRun
						  notRunCount: notRunCount ] ].
	^ self aggregateDataForResults: resultEntries timedOut: false unrunTests: #(  )
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> selectionTextOf: validatedRequest [
	"A class or method selection as the refusal writes it, by the name of the class it resolved to."

	^ String streamContents: [ :stream |
			  stream << validatedRequest testClass name.
			  validatedRequest testMethodName ifNotNil: [ :selector | stream << '>>#' << selector ] ]
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> shortenTimeLimitOf: aTestCase [
	"The test a timeout interrupts gets a second for its tearDown: SUnit's own watchdog then stops a tearDown that hangs, and the call answers about a second late. A deadline that falls outside the test's managed run has no limit to shorten."

	aTestCase executionEnvironment isTest ifTrue: [ aTestCase timeLimit: 1 second ]
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> shouldIgnoreMethodForCoverage: aCompiledMethod [

	aCompiledMethod isTestMethod ifTrue: [ ^ true ].
	aCompiledMethod methodClass instanceSide isTestCase ifTrue: [ ^ true ].
	aCompiledMethod isAbstract ifTrue: [ ^ true ].
	^ aCompiledMethod hasPragmaNamed: #ignoreForCoverage
]

{ #category : 'private' }
MCPRunTestsCommand >> testCaseDeduplicationKeyFor: aTestCase [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: aTestCase class name;
				  nextPut: $/;
				  nextPutAll: aTestCase selector asString;
				  nextPut: $/;
				  nextPutAll: aTestCase nameForReport ]
]

{ #category : 'private - not run' }
MCPRunTestsCommand >> testCasesByClassIn: someTestCases [
	"Each class of someTestCases, in order, with its cases among them."

	| groups |
	groups := OrderedCollection new.
	someTestCases do: [ :each |
			groups
				detect: [ :group | group key == each class ]
				ifFound: [ :group | group value add: each ]
				ifNone: [ groups add: each class -> (OrderedCollection with: each) ] ].
	^ groups
]

{ #category : 'private' }
MCPRunTestsCommand >> testCasesForPackageRequest: validatedRequest [

	^ Array streamContents: [ :stream |
			  (self testClassesInPackageNamed: validatedRequest packageName) do: [ :testClass |
				  (self testCasesFromSuite: testClass suite) do: [ :testCase | stream nextPut: testCase ] ] ]
]

{ #category : 'private' }
MCPRunTestsCommand >> testCasesForValidatedRequest: validatedRequest [

	| suite testCases testMethodSelector |
	validatedRequest isPackageRequest ifTrue: [ ^ self testCasesForPackageRequest: validatedRequest ].
	suite := validatedRequest testClass suite.
	testCases := self testCasesFromSuite: suite.
	validatedRequest testMethodName ifNotNil: [ :testMethodName |
			testMethodSelector := testMethodName asSymbol.
			^ testCases select: [ :each | each selector = testMethodSelector ] ].
	^ testCases
]

{ #category : 'private' }
MCPRunTestsCommand >> testCasesFromSuite: aSuite [

	| testCases |
	testCases := OrderedCollection new.
	self addTestCasesFrom: aSuite to: testCases.
	^ testCases asArray
]

{ #category : 'private' }
MCPRunTestsCommand >> testClassesInPackageNamed: packageName [

	| package |
	package := MCPImageLookup packageNamed: packageName.
	^ (package definedClasses select: [ :each | each isTestCase and: [ each isAbstract not ] ]) asArray sort: [ :left :right |
		  left name <= right name ]
]

{ #category : 'private' }
MCPRunTestsCommand >> testRequestForTestCase: aTestCase [

	^ MCPTestRunRequest className: aTestCase class name asString testMethodName: aTestCase selector asString
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> textForMethod: aSelectionText notATestOf: aClassName [
	"The class's tests are the answer, so SUnit's rule for a test selector is not spelt out."

	^ String streamContents: [ :stream |
			  stream << aSelectionText << ' is not one of ' << aClassName
			  << '''s tests. Name one of its test methods, or the class to run them all.' ]
]

{ #category : 'private' }
MCPRunTestsCommand >> uniqueTestCasesFrom: testCases seenTestCaseNames: seenTestCaseNames [

	| uniqueTestCases |
	uniqueTestCases := OrderedCollection new.
	testCases do: [ :testCase |
			| testCaseName |
			testCaseName := self testCaseDeduplicationKeyFor: testCase.
			(seenTestCaseNames includes: testCaseName) ifFalse: [
					seenTestCaseNames add: testCaseName.
					uniqueTestCases add: testCase ] ].
	^ uniqueTestCases asArray
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> validatedRequestsFrom: testRequests [
	"Every name is resolved first, in the order the selections come, packages, classes, methods: the first that names nothing refuses the call alone, in the lookup's words. Then every selection that is no test is refused, all in one refusal. Either way nothing has run."

	| validatedRequests |
	validatedRequests := testRequests collect: [ :each | self resolvedRequestFor: each ].
	self refuseSelectionsThatAreNotTests: validatedRequests.
	^ validatedRequests
]

{ #category : 'private - without tests' }
MCPRunTestsCommand >> withoutTestsEntryFor: validatedRequest [
	"The selection, as the answer names it, and why it selected no test."

	^ Dictionary new
		  at: #selection put: (validatedRequest isPackageRequest
				   ifTrue: [ validatedRequest packageName ]
				   ifFalse: [ self selectionTextOf: validatedRequest ]);
		  at: #reason put: 'has no tests';
		  yourself
]

{ #category : 'private - without tests' }
MCPRunTestsCommand >> withoutTestsIn: validatedRequests [
	"One entry per selection that selected no test, in selection order, counted before an earlier selection takes any of its cases."

	^ (validatedRequests select: [ :each | (self testCasesForValidatedRequest: each) isEmpty ])
		  collect: [ :each | self withoutTestsEntryFor: each ]
		  as: Array
]
