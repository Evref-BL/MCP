"
Runs test selections until a deadline: the operation behind test_run.

Every selection is resolved and checked before any test runs. Each test then runs into a result of its own, so that it counts once, until the deadline stops one, and what is left is listed as selections to run next. It answers an MCPRunTestsResult.
"
Class {
	#name : 'MCPRunTestsCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'selections',
		'timeoutMilliseconds'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRunTestsCommand class >> selections: someSelections timeoutMilliseconds: anInteger [
	"Runs the selections until the deadline."

	^ self new initializeSelections: someSelections timeoutMilliseconds: anInteger
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
	^ self runSelectionsUntil: deadline
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> hasTimedOutAt: deadline [

	^ (self millisecondsRemainingUntil: deadline) <= 0
]

{ #category : 'initialization' }
MCPRunTestsCommand >> initializeSelections: someSelections timeoutMilliseconds: anInteger [

	selections := someSelections.
	timeoutMilliseconds := anInteger
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> interruptedTearDownTimeLimit [
	"How long the test a timeout interrupts has for its tearDown, after which SUnit's own watchdog stops a tearDown that hangs."

	^ 1 second
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> isTestSelector: aSelector in: aTestClass [
	"Whether a test_run selection that names aSelector in aTestClass runs it as a test: the class answers it, and the class's suite holds a case of it. A class that uses a trait can leave out the trait's test, and a trait's helper is no test anywhere."

	^ (aTestClass lookupSelector: aSelector) isNotNil and: [
		  (self testCasesFromSuite: aTestClass suite) anySatisfy: [ :each | each selector == aSelector ] ]
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> listPhraseForFirstFiveOf: someNames [
	"someNames as a list phrase, the first five then how many more: A, B, C, D, E and 3 more."

	^ MCPScopeQuery listPhraseFor: (someNames size > 5
			   ifTrue: [ (someNames first: 5) copyWith: (someNames size - 5) printString , ' more' ]
			   ifFalse: [ someNames ])
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

{ #category : 'private - validation' }
MCPRunTestsCommand >> notATestClassReasonOn: aStream for: aClass selection: aSelection [
	"After the words that name aClass, what it is instead of a test class, and what to do: a trait's tests run in the test classes that use it, a class becomes a test class once it subclasses TestCase, which class_update changes, and a class with no superclass is left at that."

	aClass isTrait ifTrue: [ ^ self traitTestClassesOn: aStream for: aClass selection: aSelection ].
	aClass superclass ifNil: [ ^ aStream nextPutAll: ' has no superclass, and a test class subclasses TestCase.' ].
	aStream nextPutAll: ' is a subclass of '.
	self testCaseSuperclassAdviceOn: aStream for: aClass
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

{ #category : 'private - validation' }
MCPRunTestsCommand >> refusalOf: aSelection [
	"Nil for a selection that holds tests, or a package; else its sentence and its entry. A test class whose suite holds no case of the method is refused, and so is any class that is not a test class, saying what it is instead."

	| entry selectionText testClass |
	aSelection isPackageSelection ifTrue: [ ^ nil ].
	testClass := aSelection testClass.
	selectionText := aSelection resolvedName.
	entry := Dictionary new.
	entry at: #selection put: selectionText.
	entry at: #class put: testClass name asString.
	testClass isTestCase ifFalse: [
			^ (String streamContents: [ :stream |
					   aSelection hasTestMethod
						   ifTrue: [ stream << selectionText << ' is not a test: ' << testClass name ]
						   ifFalse: [ stream << testClass name << ' is not a test class: it' ].
					   self notATestClassReasonOn: stream for: testClass selection: aSelection ]) -> entry ].
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
			resultEntries add: (MCPTestRunInfo outcomes: outcomes).
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
	"The test a timeout interrupts gets a short time for its tearDown, so the call answers about that much late. A deadline that falls outside the test's managed run has no limit to shorten."

	aTestCase executionEnvironment isTest ifTrue: [ aTestCase timeLimit: self interruptedTearDownTimeLimit ]
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

{ #category : 'private - validation' }
MCPRunTestsCommand >> testCaseSuperclassAdviceOn: aStream for: aClass [
	"A class made with no superclass subclasses Object, so the advice says what a test class subclasses and how to change it, with the call to class_update itself, which tools/list advertises."

	aStream
		nextPutAll: aClass superclass name;
		nextPutAll: ', and a test class subclasses TestCase. If ';
		nextPutAll: aClass name;
		nextPutAll: ' is meant to hold tests, make TestCase its superclass with class_update {"name": "';
		nextPutAll: aClass name;
		nextPutAll: '", "superclass": "TestCase"}.'
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
MCPRunTestsCommand >> testClassesUsing: aTrait [
	"The test classes that use aTrait, directly or through the traits that use it, sorted by name."

	| classes traits |
	classes := IdentitySet new.
	traits := OrderedCollection with: aTrait.
	[ traits isEmpty ] whileFalse: [
			traits removeFirst users do: [ :each |
					each isTrait
						ifTrue: [ traits add: each ]
						ifFalse: [ each isTestCase ifTrue: [ classes add: each ] ] ] ].
	^ classes asArray sort: [ :left :right | left name <= right name ]
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

{ #category : 'private - validation' }
MCPRunTestsCommand >> traitMethodAdviceOn: aStream for: aSelection in: someTestClasses [
	"After the test classes that use the method's trait: the method named in the first of them, by name, that runs it as a test, and which ones do when not all of them do. When none does, the method is a helper, or each of them leaves it out, so their test methods or the classes themselves are named instead."

	| names runners |
	runners := someTestClasses select: [ :each | self isTestSelector: aSelection testMethodName asSymbol in: each ].
	runners ifEmpty: [
			someTestClasses size = 1 ifFalse: [
					^ aStream nextPutAll:
						  'None of them runs that method as a test: name one of their test methods instead, or one of them to run all its tests.' ].
			^ aStream
				  nextPutAll: someTestClasses first name;
				  nextPutAll: ' does not run that method as a test: name one of its test methods instead, or ';
				  nextPutAll: someTestClasses first name;
				  nextPutAll: ' to run them all.' ].
	names := runners collect: [ :each | each name asString ].
	runners size = someTestClasses size
		ifTrue: [
				aStream nextPutAll: (names size = 1
						 ifTrue: [ 'Name ' ]
						 ifFalse: [ 'Name the method in one of them instead, as ' ]) ]
		ifFalse: [
				aStream
					nextPutAll: 'Only ';
					nextPutAll: (self listPhraseForFirstFiveOf: names);
					nextPutAll: (names size = 1
							 ifTrue: [ ' runs that method as a test: name ' ]
							 ifFalse: [ ' run that method as a test: name it in one of them instead, as ' ]) ].
	aStream
		nextPutAll: names first;
		nextPutAll: '>>#';
		nextPutAll: aSelection testMethodName;
		nextPutAll: (names size = 1
				 ifTrue: [ ' instead.' ]
				 ifFalse: [ '.' ])
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> traitTestClassesOn: aStream for: aTrait selection: aSelection [
	"After the words that name the trait: that it is one, and the test classes that run its tests, the first five then how many more, with what to name instead. A method is named in a class that runs it as a test."

	| names users |
	users := self testClassesUsing: aTrait.
	users ifEmpty: [
		^ aStream nextPutAll: ' is a trait, and no test class uses it. A trait''s tests run in the test classes that use it.' ].
	names := users collect: [ :each | each name asString ].
	aStream
		nextPutAll: ' is a trait, and its tests run in the test classes that use it: ';
		nextPutAll: (self listPhraseForFirstFiveOf: names);
		nextPutAll: '. '.
	aSelection hasTestMethod ifTrue: [ ^ self traitMethodAdviceOn: aStream for: aSelection in: users ].
	names size = 1 ifFalse: [ ^ aStream nextPutAll: 'Name one of them instead.' ].
	aStream
		nextPutAll: 'Name ';
		nextPutAll: names first;
		nextPutAll: ' instead.'
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
