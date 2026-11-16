"
Runs test selections until a deadline: the operation behind test_run and test_coverage_run.

Every selection is resolved and checked before any test runs. Each test then runs into a result of its own, so that it counts once, until the deadline stops one, and what is left is listed as selections to run next. Given a coverage scope, it also measures which of the scope's methods the tests executed. It answers an MCPRunTestsResult.
"
Class {
	#name : 'MCPRunTestsCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'selections',
		'timeoutMilliseconds',
		'coverageScope',
		'includeCoveredMethods',
		'methodLimit'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRunTestsCommand class >> selections: someSelections timeoutMilliseconds: anInteger [
	"Runs the selections until the deadline, measuring no coverage."

	^ self
		  selections: someSelections
		  timeoutMilliseconds: anInteger
		  coverageScope: nil
		  includeCoveredMethods: false
		  methodLimit: 0
]

{ #category : 'instance creation' }
MCPRunTestsCommand class >> selections: someSelections timeoutMilliseconds: anInteger coverageScope: aScopeQueryOrNil includeCoveredMethods: aBoolean methodLimit: aLimit [
	"Runs the selections until the deadline, measuring the coverage of the methods aScopeQueryOrNil selects, if any. Coverage lists at most aLimit methods each, and the covered ones only when aBoolean is true."

	^ self new
		  initializeSelections: someSelections
		  timeoutMilliseconds: anInteger
		  coverageScope: aScopeQueryOrNil
		  includeCoveredMethods: aBoolean
		  methodLimit: aLimit
]

{ #category : 'private - not run' }
MCPRunTestsCommand >> addNotRunStartingAt: startIndex seenTestCaseNames: seenTestCaseNames to: notRun [
	"The selections from startIndex on, after the one a timeout fell in, each whole when none of its cases was lost to an earlier selection, else its cases as methods. Answers how many tests they hold."

	| count |
	count := 0.
	startIndex to: selections size do: [ :index |
			| selection testCases uniqueTestCases |
			selection := selections at: index.
			testCases := self testCasesFor: selection.
			uniqueTestCases := self uniqueTestCasesFrom: testCases seenTestCaseNames: seenTestCaseNames.
			count := count + uniqueTestCases size.
			uniqueTestCases ifNotEmpty: [
					notRun addAll: (uniqueTestCases size = testCases size
							 ifTrue: [ { selection } ]
							 ifFalse: [ self methodSelectionsForTestCases: uniqueTestCases ]) ] ].
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
MCPRunTestsCommand >> coverableMethods [

	^ (coverageScope methods reject: [ :method | self shouldIgnoreMethodForCoverage: method ]) asArray
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> coverageCollectorForMethods: methods [

	| collector |
	collector := self coverageCollectorClass new.
	collector methods: methods.
	^ collector
]

{ #category : 'accessing' }
MCPRunTestsCommand >> coverageScope [
	"The methods whose coverage the run measures, as a scope query that holds the warnings it raised once run, or nil."

	^ coverageScope
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> deadlineForTimeoutMilliseconds: milliseconds [

	^ Time millisecondClockValue + milliseconds
]

{ #category : 'executing' }
MCPRunTestsCommand >> execute [
	"Every selection is resolved and checked before the deadline starts, then they run until it."

	| deadline |
	self validateSelections.
	deadline := self deadlineForTimeoutMilliseconds: timeoutMilliseconds.
	^ coverageScope ifNil: [ self runSelectionsUntil: deadline ] ifNotNil: [ self runCoverageUntil: deadline ]
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

{ #category : 'initialization' }
MCPRunTestsCommand >> initializeSelections: someSelections timeoutMilliseconds: anInteger coverageScope: aScopeQueryOrNil includeCoveredMethods: aBoolean methodLimit: aLimit [

	selections := someSelections.
	timeoutMilliseconds := anInteger.
	coverageScope := aScopeQueryOrNil.
	includeCoveredMethods := aBoolean.
	methodLimit := aLimit
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> locationOf: aContext in: aTestCase [
	"Where the test was running when the timeout fell, unless that was the test method."

	^ MCPStructuredTestResult locationOf: aContext in: aTestCase
]

{ #category : 'private - not run' }
MCPRunTestsCommand >> methodSelectionsForTestCases: someTestCases [
	"One method each, in order, so that the cases of a parameterized test name their method once."

	| names |
	names := Set new.
	^ Array streamContents: [ :stream |
			  someTestCases do: [ :each |
					  | selection |
					  selection := self selectionForTestCase: each.
					  (names includes: selection displayName) ifFalse: [
							  names add: selection displayName.
							  stream nextPut: selection ] ] ]
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> millisecondsRemainingUntil: deadline [

	^ 0 max: deadline - Time millisecondClockValue
]

{ #category : 'private - not run' }
MCPRunTestsCommand >> notRunSelectionsFor: aSelection testCases: testCases uniqueTestCases: uniqueTestCases startingAt: startIndex [
	"What is left of the selection a timeout fell in, as test_run arguments: the selection itself when none of its cases ran or was lost to an earlier selection; else, for a package, each class from the interrupted one on, whole when none of its cases ran or was lost, else its cases left as methods; for a class or a method, its cases left as methods."

	| left |
	(startIndex = 1 and: [ uniqueTestCases size = testCases size ]) ifTrue: [ ^ { aSelection } ].
	left := uniqueTestCases allButFirst: startIndex - 1.
	aSelection isPackageSelection ifFalse: [ ^ self methodSelectionsForTestCases: left ].
	^ Array streamContents: [ :stream |
			  (self testCasesByClassIn: left) do: [ :each |
					  (testCases count: [ :testCase | testCase class == each key ]) = each value size
						  ifTrue: [ stream nextPut: (MCPTestSelectionSpec className: each key name asString) ]
						  ifFalse: [ stream nextPutAll: (self methodSelectionsForTestCases: each value) ] ] ]
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> partiallyCoveredMethodsFromCoverageResult: coverageResult [

	^ (coverageResult methods select: [ :method | (self hasAllSequenceNodesCoveredIn: method) not ]) asArray
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> refusalOf: aSelection [
	"Nil for a selection that holds tests, or a package; else its sentence and its entry. A test class whose suite holds no case of the method is refused, and so is any class that is not a test class."

	| entry selectionText testClass |
	aSelection isPackageSelection ifTrue: [ ^ nil ].
	testClass := aSelection testClass.
	selectionText := aSelection resolvedName.
	entry := Dictionary new.
	entry at: #selection put: selectionText.
	entry at: #class put: testClass name asString.
	testClass isTestCase ifFalse: [
			^ (String streamContents: [ :stream |
					   aSelection hasTestMethod ifTrue: [ stream << selectionText << ' is not a test: ' ].
					   stream << testClass name << ' is not a test class.' ]) -> entry ].
	aSelection hasTestMethod ifFalse: [ ^ nil ].
	(self testCasesFor: aSelection) ifNotEmpty: [ ^ nil ].
	^ (self textForMethod: selectionText notATestOf: testClass name) -> entry
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> refuseSelectionsThatAreNotTests [
	"One sentence per selection that is no test, in selection order, all in one refusal."

	| refusals |
	refusals := (selections collect: [ :each | self refusalOf: each ]) reject: [ :each | each isNil ].
	refusals ifEmpty: [ ^ self ].
	MCPCommandError
		signalErrorCode: ((selections anySatisfy: [ :each | each isPackageSelection not and: [ each testClass isTestCase not ] ])
				 ifTrue: [ #NotATestClass ]
				 ifFalse: [ #NotATest ])
		message: (' ' join: (refusals collect: [ :each | each key ]))
		details: { (#notTests -> (refusals collect: [ :each | each value ] as: Array)) } asDictionary
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> resolve: aSelection [
	"Looks up what aSelection names, refusing it in the lookup's words when it names nothing. A method is looked up as its class answers it, so a test the class inherits is found."

	| testClass |
	aSelection isPackageSelection ifTrue: [ ^ MCPImageLookup packageNamed: aSelection packageName ].
	testClass := aSelection testClass.
	aSelection testMethodName ifNotNil: [ :selector |
		(testClass lookupSelector: selector asSymbol) ifNil: [ MCPCommandError signalMissingMethod: selector in: testClass ] ]
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> runCoverageUntil: deadline [

	| collector coverageResult partialMethods runResult |
	collector := self coverageCollectorForMethods: self coverableMethods.
	[
		collector installOn: [
				collector reset.
				runResult := self runSelectionsUntil: deadline.
				"Collect before resetting annotations so partial node coverage remains observable."
				collector remapMethods.
				coverageResult := collector basicCollectResult.
				partialMethods := self partiallyCoveredMethodsFromCoverageResult: coverageResult ] ] ensure: [ collector reset ].
	runResult coverage: (MCPTestCoverageResult
			 coverageResult: coverageResult
			 includeCoveredMethods: includeCoveredMethods
			 methodLimit: methodLimit
			 partiallyCoveredMethods: partialMethods).
	^ runResult
]

{ #category : 'private' }
MCPRunTestsCommand >> runEachSelectionUntil: deadline [
	"Runs the selections in order until the deadline. The first test it stops ends the run, and what is left of its selection and of the later ones is listed to run next."

	| resultEntries seenTestCaseNames |
	resultEntries := OrderedCollection new.
	seenTestCaseNames := Set new.
	selections withIndexDo: [ :selection :index |
			| notRun notRunCount outcomes stopped testCases uniqueTestCases |
			(self hasTimedOutAt: deadline) ifTrue: [
					notRun := OrderedCollection new.
					notRunCount := self addNotRunStartingAt: index seenTestCaseNames: seenTestCaseNames to: notRun.
					^ self
						  timedOutResultFor: resultEntries
						  interruption: nil
						  notRun: notRun
						  notRunCount: notRunCount ].
			testCases := self testCasesFor: selection.
			uniqueTestCases := self uniqueTestCasesFrom: testCases seenTestCaseNames: seenTestCaseNames.
			outcomes := OrderedCollection new.
			stopped := self runTestCases: uniqueTestCases until: deadline into: outcomes.
			resultEntries add: (MCPTestRunInfo validatedRequest: selection selectedTestCount: uniqueTestCases size outcomes: outcomes).
			stopped ifNotNil: [
					notRun := OrderedCollection withAll: (self
							           notRunSelectionsFor: selection
							           testCases: testCases
							           uniqueTestCases: uniqueTestCases
							           startingAt: outcomes size + 1).
					notRunCount := uniqueTestCases size - outcomes size
					               + (self addNotRunStartingAt: index + 1 seenTestCaseNames: seenTestCaseNames to: notRun).
					^ self
						  timedOutResultFor: resultEntries
						  interruption: (stopped isInterrupted ifTrue: [ stopped ])
						  notRun: notRun
						  notRunCount: notRunCount ] ].
	^ self aggregateDataForResults: resultEntries timedOut: false unrunTests: #(  )
]

{ #category : 'private' }
MCPRunTestsCommand >> runSelectionsUntil: deadline [
	"Runs the selections in order until the deadline, then lists what was not run. The selections that hold no test are said whatever the deadline, since running cannot change that."

	^ (self runEachSelectionUntil: deadline)
		  withoutTests: (selections select: [ :each | (self testCasesFor: each) isEmpty ]);
		  yourself
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
MCPRunTestsCommand >> runTestCases: someTestCases until: deadline into: outcomes [
	"Each test runs into a result of its own, so that SUnit counts it once however many exceptions it raised. Adds the outcome of each test that finished, in order, and answers the first the deadline stops, or nil when it stopped none."

	someTestCases do: [ :each |
			| outcome |
			outcome := self runTestCase: each into: MCPStructuredTestResult new deadline: deadline.
			outcome isFinished ifFalse: [ ^ outcome ].
			outcomes add: outcome ].
	^ nil
]

{ #category : 'private - not run' }
MCPRunTestsCommand >> selectionForTestCase: aTestCase [

	^ MCPTestSelectionSpec className: aTestCase class name asString testMethodName: aTestCase selector asString
]

{ #category : 'accessing' }
MCPRunTestsCommand >> selections [

	^ selections
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
MCPRunTestsCommand >> testCasesFor: aSelection [

	| testCases testMethodSelector |
	aSelection isPackageSelection ifTrue: [ ^ self testCasesForPackageNamed: aSelection packageName ].
	testCases := self testCasesFromSuite: aSelection testClass suite.
	aSelection testMethodName ifNotNil: [ :testMethodName |
			testMethodSelector := testMethodName asSymbol.
			^ testCases select: [ :each | each selector = testMethodSelector ] ].
	^ testCases
]

{ #category : 'private' }
MCPRunTestsCommand >> testCasesForPackageNamed: aPackageName [

	^ Array streamContents: [ :stream |
			  (self testClassesInPackageNamed: aPackageName) do: [ :testClass |
				  (self testCasesFromSuite: testClass suite) do: [ :testCase | stream nextPut: testCase ] ] ]
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

{ #category : 'private - validation' }
MCPRunTestsCommand >> textForMethod: aSelectionText notATestOf: aClassName [
	"The class's tests are the answer, so SUnit's rule for a test selector is not spelt out."

	^ String streamContents: [ :stream |
			  stream << aSelectionText << ' is not one of ' << aClassName
			  << '''s tests. Name one of its test methods, or the class to run them all.' ]
]

{ #category : 'private' }
MCPRunTestsCommand >> timedOutResultFor: resultEntries interruption: anOutcomeOrNil notRun: someSelections notRunCount: aCount [
	"After a timeout. One that leaves no test unrun is not reported."

	aCount isZero ifTrue: [ ^ self aggregateDataForResults: resultEntries timedOut: false unrunTests: #(  ) ].
	^ (self aggregateDataForResults: resultEntries timedOut: true unrunTests: someSelections)
		  interruption: anOutcomeOrNil;
		  notRunCount: aCount;
		  timeoutMilliseconds: timeoutMilliseconds;
		  yourself
]

{ #category : 'accessing' }
MCPRunTestsCommand >> timeoutMilliseconds [

	^ timeoutMilliseconds
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
MCPRunTestsCommand >> validateSelections [
	"Every name is resolved first, in the order the selections come, packages, classes, methods: the first that names nothing refuses the call alone, in the lookup's words. Then every selection that is no test is refused, all in one refusal. Either way nothing has run."

	selections do: [ :each | self resolve: each ].
	self refuseSelectionsThatAreNotTests
]
