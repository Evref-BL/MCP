"
Tests what test_run and test_coverage_run run and say: which selections they refuse before anything runs, how each test is counted once, where an issue came from, and what a timeout leaves to run.

The fixtures it runs are named by string, so that these tests add no reference to them: some of the tests count the test classes that refer to a class.
"
Class {
	#name : 'MCPToolRunTestsTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private - running' }
MCPToolRunTestsTest >> commandResultFor: someArguments [
	"What test_run's operation answers, before the tool words it."

	| tool |
	tool := MCPToolRunTests new.
	^ (tool operationFor: (tool requestFromToolCallArguments: someArguments asDictionary)) execute
]

{ #category : 'private - running' }
MCPToolRunTestsTest >> commandResultForClasses: classNames timeoutMilliseconds: milliseconds [
	"What test_run's operation answers for a timeout finer than timeoutSeconds can say."

	^ (MCPRunTestsCommand
		   selections: (classNames collect: [ :each | MCPTestSelectionSpec className: each ] as: Array)
		   timeoutMilliseconds: milliseconds) execute
]

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> fixtureNamed: aClassName [
	"A fixture by its name, so that this class adds no reference to it."

	^ Smalltalk globals at: aClassName asSymbol
]

{ #category : 'private - running' }
MCPToolRunTestsTest >> issueLinesFrom: aResult [
	"The lines that say an issue, in the order the answer says them."

	^ (self textFrom: aResult) lines select: [ :each |
		  #( 'failed ' 'error ' 'skipped ' ) anySatisfy: [ :prefix | each beginsWith: prefix ] ]
]

{ #category : 'private - running' }
MCPToolRunTestsTest >> onlyIssueOf: anOutcome [

	self assert: anOutcome issues size equals: 1.
	^ anOutcome issues first
]

{ #category : 'private - running' }
MCPToolRunTestsTest >> outcomesFor: someArguments [

	^ (self commandResultFor: someArguments) outcomes
]

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> resetCountingFixture [

	(self fixtureNamed: 'MCPToolRunTestsCountingTarget') resetRuns
]

{ #category : 'private - running' }
MCPToolRunTestsTest >> runTests: someArguments [

	^ self callToolNamed: 'test_run' withArguments: someArguments asDictionary
]

{ #category : 'private - running' }
MCPToolRunTestsTest >> summaryForResult: aRunTestsResult [
	"What test_run says of what its command answered."

	^ MCPToolRunTests new successSummaryForData: aRunTestsResult asDictionary
]

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testABlankOnlyArgumentNamesNothingToActOn [

	self
		assertResult: (self callToolNamed: 'test_run' withArguments: { (#methods -> #( '  ' )) } asDictionary)
		refusesArgumentsSaying: 'methods names nothing to act on; give at least one value that is not blank.'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAClassReadWithItsSideRunsTheClassTests [

	| data |
	data := self dataFrom:
		        (self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'MCPToolRunTestsTimeoutTarget class' )) } asDictionary).
	self assert: (data at: #runCount) equals: 2
]

{ #category : 'tests - selections without tests' }
MCPToolRunTestsTest >> testAClassWithoutTestsSaysSo [

	self
		assert: (self summaryFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsEmptyTarget' )) }))
		equals: 'Ran 0 tests (0 passed). MCPToolRunTestsEmptyTarget has no tests.'
]

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testACoverageScopeEntryThatNamesNoClassIsSaid [
	"The coverage scope answers partial results, as a search scope does, so an entry that names nothing is skipped with a warning, not dropped without a word. Pharo 10 has no coverage to collect and refuses the call."

	| result |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			          (#classes -> #( 'MCPToolCoverageTargetTest' )).
			          (#coverage -> { (#scope -> { (#classes -> #( 'Zzqxw' 'MCPToolCoverageTarget' )) } asDictionary) } asDictionary) }
			          asDictionary.
	self coverageIsAvailable ifFalse: [ ^ self assert: (self resultIndicatesError: result) ].
	self deny: (self resultIndicatesError: result).
	self assert: (self warningsFrom: result) asArray equals: #( 'Class Zzqxw does not exist, so scope.classes skipped it.' ).
	self assert: (((self dataFrom: result) at: #coverage) at: #methodCount) > 0
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAFailureFollowedByATearDownErrorIsOneErroredTest [

	| data result |
	result := self runTests: { (#classes -> #( 'MCPToolRunTestsFailThenTearDownTarget' )) }.
	data := self dataFrom: result.
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #errorCount) equals: 1.
	self deny: (data includesKey: #failureCount).
	self
		assert: (self issueLinesFrom: result)
		equals: #( 'failed MCPToolRunTestsFailThenTearDownTarget>>#testFails: Assertion failed, at self assert: false'
			   'error MCPToolRunTestsFailThenTearDownTarget>>#testFails (Error): tearDown broken, in MCPToolRunTestsFailThenTearDownTarget>>tearDown' )
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAFixtureThatFailsTwiceCountsEachTestOnce [
	"The message is not asserted: its wording differs before Pharo 12."

	| data lines outcomes result |
	result := self runTests: { (#classes -> #( 'MCPToolRunTestsBrokenFixtureTarget' )) }.
	data := self dataFrom: result.
	self assert: (data at: #runCount) equals: 2.
	self assert: (data at: #errorCount) equals: 2.
	self deny: (data includesKey: #failureCount).
	self assert: ((self summaryFrom: result) beginsWith: 'Ran 2 tests (0 passed). 2 errors.').
	lines := self issueLinesFrom: result.
	self assert: lines size equals: 1.
	self assert: (lines first beginsWith:
			 'error MCPToolRunTestsBrokenFixtureTarget>>#testOne, MCPToolRunTestsBrokenFixtureTarget>>#testTwo (MessageNotUnderstood)').
	self assert:
		(lines first endsWith: ', in MCPToolRunTestsBrokenFixtureTarget>>setUp and MCPToolRunTestsBrokenFixtureTarget>>tearDown').
	outcomes := (self commandResultFor: { (#classes -> #( 'MCPToolRunTestsBrokenFixtureTarget' )) }) outcomes.
	self assert: (outcomes collect: [ :each | each outcome ]) equals: #( 'error' 'error' )
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAGlobalThatIsNotAClassIsRefusedByTheLookup [

	| result |
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'Transcript' )) } asDictionary.
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'NotAClass'.
	self assert: (self summaryFrom: result) equals: 'Transcript is a global variable, not a class.'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAGroupOfSomeTestsNamesThem [

	self
		assert: (self issueLinesFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsSomeFailTarget' )) }))
		equals:
		#( 'error MCPToolRunTestsSomeFailTarget>>#testA, MCPToolRunTestsSomeFailTarget>>#testB (Error): fixture broken, in MCPToolRunTestsRaiser>>fail' )
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testALocationNamesTheMethodClassWhenItIsInherited [

	| context |
	context := Context
		           sender: nil
		           receiver: (self fixtureNamed: 'MCPToolRunTestsInheritingTarget') new
		           method: TestCase >> #setUp
		           arguments: #(  ).
	self assert: (MCPStructuredTestResult locationTextOf: context) equals: 'MCPToolRunTestsInheritingTarget(TestCase)>>setUp'.
	context := Context
		           sender: nil
		           receiver: (self fixtureNamed: 'MCPToolRunTestsInheritingTarget')
		           method: (self fixtureNamed: 'MCPToolRunTestsAbstractTarget') class >> #isAbstract
		           arguments: #(  ).
	self
		assert: (MCPStructuredTestResult locationTextOf: context)
		equals: 'MCPToolRunTestsInheritingTarget class(MCPToolRunTestsAbstractTarget class)>>isAbstract'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testALoneFailureNamesItsStatement [

	self
		assert: (self issueLinesFrom: (self runTests: { (#methods -> #( 'MCPToolRunTestsLocationTarget>>#testEqualityFails' )) }))
		equals: #( 'failed MCPToolRunTestsLocationTarget>>#testEqualityFails: Got 1 instead of 2, at self assert: 1 equals: 2' ).
	self
		assert: (self issueLinesFrom: (self runTests: { (#methods -> #( 'MCPToolStructuredOutputTestTarget>>#testFails' )) }))
		equals:
		#( 'failed MCPToolStructuredOutputTestTarget>>#testFails: boom failure, at self assert: false description: ''boom failure''' )
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAMethodOfANonTestClassIsRefused [

	| summary |
	summary := self summaryFrom:
		           (self
			            callToolNamed: 'test_run'
			            withArguments: { (#methods -> #( 'MCPToolCoverageTarget>>#coveredMethod' )) } asDictionary).
	self assert: summary equals: 'MCPToolCoverageTarget>>#coveredMethod is not a test: MCPToolCoverageTarget is not a test class.'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAMethodThatIsNotATestIsRefused [

	| result |
	result := self
		          callToolNamed: 'test_run'
		          withArguments: { (#methods -> #( 'MCPToolStructuredOutputTestTarget>>#setUp' )) } asDictionary.
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'NotATest'.
	self
		assert: (self summaryFrom: result)
		equals:
		'MCPToolStructuredOutputTestTarget>>#setUp is not one of MCPToolStructuredOutputTestTarget''s tests. Name one of its test methods, or the class to run them all.'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAMissingNameIsRefusedBeforeAnyTestCheck [

	| result |
	result := self
		          callToolNamed: 'test_run'
		          withArguments: { (#classes -> #( 'MCPToolRunTestsUnreferencedTarget' 'Zzqxw' )) } asDictionary.
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'ClassNotFound'.
	self deny: ((self summaryFrom: result) includesSubstring: 'is not a test class')
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testANonTestClassIsRefused [

	| result |
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'MCPToolRunTestsUnreferencedTarget' )) } asDictionary.
	self assert: (self resultIndicatesError: result).
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'NotATestClass'.
	self assert: (self summaryFrom: result) equals: 'MCPToolRunTestsUnreferencedTarget is not a test class.'
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testANotRunSelectionThatLostCasesIsListedByMethod [
	"The abstract class's suite holds the inheriting class's case, which the first selection already ran, so the abstract class is not passed back whole. The request order is packages, classes, methods, so an earlier selection takes some of a class's cases only through an abstract class."

	| data notRun result |
	result := self
		          commandResultForClasses: #( 'MCPToolRunTestsInheritingTarget' 'MCPToolRunTestsAbstractTarget' )
		          timeoutMilliseconds: 200.
	data := result asDictionary.
	notRun := data at: #notRun.
	self assert: (data at: #timedOut).
	self deny: (notRun includesKey: #classes).
	self assert: ((notRun at: #methods) includes: 'MCPToolRunTestsSlowInheritingTarget>>#testWaits').
	self assert: (data at: #interrupted) equals: { (#test -> 'MCPToolRunTestsSlowInheritingTarget>>#testWaits') } asDictionary.
	self assert: (data at: #notRunCount) equals: 1
]

{ #category : 'tests - selections without tests' }
MCPToolRunTestsTest >> testAPackageWithoutTestClassesBesideOthersIsOnlyNamed [

	| count |
	count := (self fixtureNamed: 'MCPToolRunTestsPackageTarget') testSelectors size.
	self
		assert: (self summaryFrom: (self runTests: { (#packages -> #( 'MCP-Tests-RunResources' 'MCP-Tests-Resources-Extensions' )) }))
		equals: (String streamContents: [ :stream |
					 stream << 'Ran ' << (MCPToolRunTests new textForCount: count noun: 'test') << ' ('.
					 stream print: count.
					 stream << ' passed). MCP-Tests-Resources-Extensions has no tests.' ])
]

{ #category : 'tests - selections without tests' }
MCPToolRunTestsTest >> testAPackageWithoutTestClassesSaysSo [

	| result |
	result := self runTests: { (#packages -> #( 'MCP-Tests-Resources-Extensions' )) }.
	self deny: (self resultIndicatesError: result).
	self assert: (self summaryFrom: result) equals: 'Ran 0 tests (0 passed). MCP-Tests-Resources-Extensions has no tests.'.
	self assert: ((self dataFrom: result) at: #withoutTests) equals: { {
			(#selection -> 'MCP-Tests-Resources-Extensions').
			(#reason -> 'has no tests') } asDictionary }
]

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testAParameterizedCaseCanBePassedBackAsMethods [
	"A failing case is named with its parameters, the way the answer tells it apart from the cases that passed. Passing that name back as methods runs the method, every case of it."

	| name result |
	result := self runTests: { (#methods -> #( 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16' )) }.
	name := (((self dataFrom: result) at: #failures) first at: #tests) first.
	self assert: name equals: 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16 with #encoding->''UTF-16'''.
	result := self runTests: { (#methods -> { name }) }.
	self deny: (self resultIndicatesError: result) description: [ self textFrom: result ].
	self assert: (self summaryFrom: result) equals: 'Ran 3 tests (2 passed). 1 failure.'.
	self assert: (((self dataFrom: result) at: #failures) first at: #tests) equals: { name }
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testAParameterizedCaseIsNamedWithItsParameters [

	| outcomes |
	outcomes := self outcomesFor: { (#methods -> #( 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16' )) }.
	self
		assert: (outcomes select: [ :each | each isFailure ] thenCollect: [ :each | each name ])
		equals: #( 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16 with #encoding->''UTF-16''' ).
	self assert: (outcomes collect: [ :each | each reference ] as: Set) size equals: 1
]

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testAReferenceInAnyFormMethodGetAcceptsRuns [

	#( 'MCPToolRunTestsTimeoutTarget#testFastPass' 'MCPToolRunTestsTimeoutTarget >> testFastPass'
	   'MCPToolRunTestsTimeoutTarget class>>#testFastPass' ) do: [ :reference |
		self assert: (self summaryFrom: (self runTests: { (#methods -> { reference }) })) equals: 'Ran 1 test (1 passed).' ]
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testARefusalRunsNoSelection [

	| result |
	self resetCountingFixture.
	result := self
		          callToolNamed: 'test_run'
		          withArguments: { (#classes -> #( 'MCPToolRunTestsCountingTarget' 'MCPToolRunTestsUnreferencedTarget' )) } asDictionary.
	self assert: (self resultIndicatesError: result).
	self assert: (self fixtureNamed: 'MCPToolRunTestsCountingTarget') runs equals: 0
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testASkipIsItsOwnOutcome [

	| result |
	result := self commandResultFor: { (#classes -> #( 'MCPToolStructuredOutputTestTarget' )) }.
	self assert: result runCount equals: 3.
	self assert: result passedCount equals: 1.
	self assert: result failureCount equals: 1.
	self assert: result errorCount equals: 1.
	self assert: result skippedCount equals: 1.
	self
		assert: ((result outcomes detect: [ :each | each isSkipped ]) issues collect: [ :each | each at: #message ])
		equals: #( 'skip probe' )
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testAStatementIsReadOnOneLineAndCutPastAHundredCharacters [

	| statement |
	statement := (MCPStructuredTestResult statementOf: thisContext) ifNil: [
		             'no statement could be read from this context, which the assertion below then reports' ].
	self
		assert: statement
		equals: 'statement := (MCPStructuredTestResult statementOf: thisContext) ifNil: [ ''no statement could be read...'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAStatementIsSaidOnlyForAGroupOfOneTest [
	"Tests that fail the same way at different statements still group into one line, which then names no statement."

	| issue outcomes result |
	outcomes := self outcomesFor: { (#classes -> #( 'MCPToolRunTestsSomeFailTarget' )) }.
	result := MCPRunTestsResult results: #(  ) timedOut: false unrunTests: #(  ).
	issue := Dictionary new
		         at: #kind put: 'failure';
		         at: #errorClass put: #TestFailure;
		         at: #message put: 'Assertion failed';
		         at: #locations put: #(  );
		         at: #statement put: 'self assert: false';
		         yourself.
	self assert: (result entryForIssueGroup: { (outcomes first -> issue) }) equals: {
			(#tests -> { outcomes first name }).
			(#message -> 'Assertion failed').
			(#statement -> 'self assert: false') } asDictionary.
	self
		assert: (result entryForIssueGroup: {
					 (outcomes first -> issue).
					 (outcomes second -> issue) })
		equals: {
				(#tests -> ((outcomes first: 2) collect: [ :each | each name ])).
				(#message -> 'Assertion failed') } asDictionary
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testATearDownFailureAfterASetUpErrorIsLabelledAFailure [
	"The answer says failures first, then errors, whatever order the test raised them in."

	self
		assert: (self issueLinesFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsSetUpErrorTarget' )) }))
		equals: #( 'failed MCPToolRunTestsSetUpErrorTarget>>#testOne: Assertion failed, in MCPToolRunTestsSetUpErrorTarget>>tearDown'
			   'error MCPToolRunTestsSetUpErrorTarget>>#testOne (Error): fixture broken, in MCPToolRunTestsRaiser>>fail' )
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testATestPastItsTimeLimitSaysSo [

	self
		assert: (self issueLinesFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsTimeLimitTarget' )) }))
		equals:
		#( 'error MCPToolRunTestsTimeLimitTarget>>#testWaitsTooLong (TestTookTooMuchTime): took longer than its time limit of 200 milliseconds' )
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testATestThatFinishesBeforeTheTimeoutIsNotInterrupted [

	| result |
	result := self runTests: {
			          (#methods -> #( 'MCPToolRunTestsTimeoutTarget>>#testFastPass' )).
			          (#timeoutSeconds -> 30) }.
	self assert: (self summaryFrom: result) equals: 'Ran 1 test (1 passed).'.
	self deny: ((self dataFrom: result) includesKey: #timedOut)
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testATestTheDeadlineReachesFirstIsNotRunNorInterrupted [

	| result |
	result := self commandResultFor: {
			          (#classes -> #( 'MCPToolStructuredOutputTestTarget' )).
			          (#methods -> #( 'MCPToolStructuredOutputTestTarget>>#testFails' )).
			          (#timeoutSeconds -> 0) }.
	self assert: result timedOut.
	self assert: result runCount equals: 0.
	self assert: result interruption isNil.
	self assert: result unrunClassNames equals: #( 'MCPToolStructuredOutputTestTarget' ).
	self assertEmpty: result unrunMethodReferences.
	self assert: result notRunCount equals: 4
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testATimeoutThatLeavesNothingUnrunIsNotReported [

	| data |
	data := self dataFrom: (self callToolNamed: 'test_run' withArguments: {
				         (#classes -> #( 'MCPToolRunTestsEmptyTarget' )).
				         (#timeoutSeconds -> 0) } asDictionary).
	self assert: (data at: #runCount) equals: 0.
	self deny: (data includesKey: #timedOut)
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAnErrorInTheTestMethodNamesNoLocation [

	self
		assert: (self issueLinesFrom: (self runTests: { (#methods -> #( 'MCPToolStructuredOutputTestTarget>>#testErrors' )) }))
		equals: #( 'error MCPToolStructuredOutputTestTarget>>#testErrors (Error): boom error' )
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAnErrorRaisedOutsideTheTestNamesWhereItCameFrom [

	| issue lines |
	lines := self issueLinesFrom: (self runTests: { (#methods -> #( 'MCPToolRunTestsLocationTarget>>#testNilReceiver' )) }).
	self assert: lines size equals: 1.
	self assert: (lines first endsWith: ', in MCPToolRunTestsRaiser>>addToNil').
	issue := self onlyIssueOf: (self outcomesFor: { (#methods -> #( 'MCPToolRunTestsLocationTarget>>#testNilReceiver' )) }) first.
	self assert: (issue at: #errorClass) equals: #MessageNotUnderstood.
	self deny: (issue includesKey: #statement)
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAnInheritedTestMethodRuns [

	self
		assert: (self summaryFrom: (self runTests: { (#methods -> #( 'MCPToolRunTestsInheritingTarget>>#testInherited' )) }))
		equals: 'Ran 1 test (1 passed).'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAnInstanceMessageSentToTheClassSaysItsInstancesUnderstandIt [
	"A constructor compiled on the instance side reads, from a test that sends it to the class, as a message nothing understands. Its send of new says it was meant for the class side. The message is not asserted: its wording differs before Pharo 12."

	| lines |
	lines := self issueLinesFrom:
		         (self runTests: { (#methods -> #( 'MCPToolRunTestsNotUnderstoodTarget>>#testSendsAnInstanceMessageToTheClass' )) }).
	self assert: lines size equals: 1.
	self assert: (lines first beginsWith:
			 'error MCPToolRunTestsNotUnderstoodTarget>>#testSendsAnInstanceMessageToTheClass (MessageNotUnderstood): ').
	self assert: (lines first endsWith:
			 '. Instances of MCPNotUnderstoodNoteTestTarget understand withLabel:, but MCPNotUnderstoodNoteTestTarget itself does not: withLabel: is an instance-side method. It sends new to self, which instances of MCPNotUnderstoodNoteTestTarget do not understand: compile it with method_compile and side class to send it to MCPNotUnderstoodNoteTestTarget.')
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testAnInterruptedTestIsNotCountedAndDoesNotDelayTheAnswer [
	"The fixture's tearDown waits 30 seconds and its class's time limit is 5: without the second the interrupted test gets for its tearDown, the answer would take 5 seconds."

	| data milliseconds result |
	milliseconds := [ result := self commandResultForClasses: #( 'MCPToolRunTestsSlowTearDownTarget' ) timeoutMilliseconds: 200 ]
		                timeToRun asMilliSeconds.
	data := result asDictionary.
	self assert: (data at: #timedOut).
	self assert: (data at: #runCount) equals: 0.
	self deny: (data includesKey: #errors).
	self assert: (data at: #interrupted) equals: {
			(#test -> 'MCPToolRunTestsSlowTearDownTarget>>#testWaits').
			(#location -> 'MCPToolRunTestsRaiser>>waitHalfASecond') } asDictionary.
	self assert: ((data at: #notRun) at: #classes) equals: #( 'MCPToolRunTestsSlowTearDownTarget' ).
	self assert: (data at: #notRunCount) equals: 1.
	self assert: (data at: #timeoutMilliseconds) equals: 200.
	self
		assert: (self summaryForResult: result)
		equals:
		'Ran 0 tests (0 passed). Timed out after 200 milliseconds, during MCPToolRunTestsSlowTearDownTarget>>#testWaits, in MCPToolRunTestsRaiser>>waitHalfASecond. 1 test not run, listed below as test_run arguments.'.
	self
		assert: milliseconds < 3000
		description: [ String streamContents: [ :stream | stream << 'took ' << milliseconds printString << ' ms' ] ]
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAnUnexpectedPassIsAFailureThatSaysSo [

	| byName result |
	result := self runTests: { (#classes -> #( 'MCPToolRunTestsExpectedFailureTarget' )) }.
	self assert: (self summaryFrom: result) equals: 'Ran 2 tests (1 passed). 1 failure.'.
	self
		assert: (self issueLinesFrom: result)
		equals:
		#( 'failed MCPToolRunTestsExpectedFailureTarget>>#testPassesUnexpectedly: it passed, but it is marked <expectedFailure>' ).
	byName := ((self commandResultFor: { (#classes -> #( 'MCPToolRunTestsExpectedFailureTarget' )) }) outcomes collect: [ :each |
		           each selector -> each ]) asDictionary.
	self assert: (byName at: 'testFailsAsExpected') outcome equals: 'passed'.
	self assertEmpty: (byName at: 'testFailsAsExpected') issues.
	self assert: (byName at: 'testPassesUnexpectedly') outcome equals: 'failure'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testCoverageAfterATimeoutIsCoverageSoFar [
	"Coverage measured over the tests that ran before a timeout is not the coverage of the call's tests."

	| data tool |
	tool := MCPToolRunTestCoverage new.
	data := Dictionary new
		        at: #runCount put: 2;
		        at: #passedCount put: 2;
		        at: #coverage put: { (#percentage -> 50) } asDictionary;
		        yourself.
	self assert: (tool successSummaryForData: data) equals: 'Ran 2 tests (2 passed). Coverage: 50.00%.'.
	data
		at: #timedOut put: true;
		at: #timeoutMilliseconds put: 2000;
		at: #notRunCount put: 3.
	self
		assert: (tool successSummaryForData: data)
		equals:
		'Ran 2 tests (2 passed). Timed out after 2 seconds. 3 tests not run, listed below as test_coverage_run arguments. Coverage so far: 50.00%.'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testCoverageLeavesOutTheRunnersOwnLookups [
	"A selection's class is looked up before the coverage collector is installed, so the runner's lookups never count as executed: MCPToolCoverageTargetTest's tests reach no method of MCPImageLookup. Pharo 10 has no coverage to collect and refuses the call."

	| result |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			          (#classes -> #( 'MCPToolCoverageTargetTest' )).
			          (#coverage -> { (#scope -> { (#classes -> #( 'MCPImageLookup' )) } asDictionary) } asDictionary) } asDictionary.
	self coverageIsAvailable ifFalse: [ ^ self assert: (self resultIndicatesError: result) ].
	self deny: (self resultIndicatesError: result).
	self assert: (((self dataFrom: result) at: #coverage) at: #coveredMethodCount) equals: 0
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testDurationsReadInWholeSecondsOrMilliseconds [

	self assert: (MCPStructuredTestResult textForDuration: 1 second) equals: '1 second'.
	self assert: (MCPStructuredTestResult textForDuration: 90 seconds) equals: '90 seconds'.
	self assert: (MCPStructuredTestResult textForDuration: 200 milliSeconds) equals: '200 milliseconds'.
	self assert: (MCPStructuredTestResult textForDuration: 1 milliSecond) equals: '1 millisecond'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testEveryBadSelectionIsNamedInOneRefusal [

	| error notTests result |
	result := self callToolNamed: 'test_run' withArguments: {
			          (#classes -> #( 'MCPToolRunTestsUnreferencedTarget' )).
			          (#methods -> #( 'MCPToolStructuredOutputTestTarget>>#setUp' )) } asDictionary.
	error := self errorFrom: result.
	notTests := error at: #notTests.
	self assert: (error at: #errorCode) equals: 'NotATestClass'.
	self
		assert: (self summaryFrom: result)
		equals:
		'MCPToolRunTestsUnreferencedTarget is not a test class. MCPToolStructuredOutputTestTarget>>#setUp is not one of MCPToolStructuredOutputTestTarget''s tests. Name one of its test methods, or the class to run them all.'.
	self assert: notTests size equals: 2.
	self assert: notTests first equals: {
			(#selection -> 'MCPToolRunTestsUnreferencedTarget').
			(#class -> 'MCPToolRunTestsUnreferencedTarget') } asDictionary.
	self assert: notTests second equals: {
			(#selection -> 'MCPToolStructuredOutputTestTarget>>#setUp').
			(#class -> 'MCPToolStructuredOutputTestTarget') } asDictionary
]

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testEveryMalformedReferenceIsNamed [

	| result |
	result := self callToolNamed: 'test_run' withArguments: { (#methods -> #( 'A' 'B' )) } asDictionary.
	self assertResult: result refusesArgumentsSaying: 'methods: A'.
	self
		assert: (self summaryFrom: result)
		equals:
		'Invalid arguments for test_run. methods: A is not a method reference; write it as Class>>#selector. methods: B is not a method reference; write it as Class>>#selector.'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testIdenticalErrorsInSeveralTestsAreSaidOnce [

	| lines |
	lines := self issueLinesFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsBrokenFixtureTarget' )) }).
	self assert: lines size equals: 1.
	self assert:
		(lines first includesSubstring: 'MCPToolRunTestsBrokenFixtureTarget>>#testOne, MCPToolRunTestsBrokenFixtureTarget>>#testTwo').
	lines := self issueLinesFrom: (self runTests: { (#methods -> #( 'MCPToolRunTestsBrokenFixtureTarget>>#testOne' )) }).
	self assert: lines size equals: 1.
	self assert: (lines first beginsWith: 'error MCPToolRunTestsBrokenFixtureTarget>>#testOne (')
]

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testNoSelectionAsksForOne [

	self
		assertResult: (self callToolNamed: 'test_run' withArguments: { (#timeoutSeconds -> 5) } asDictionary)
		refusesArgumentsSaying: 'Name at least one package, class or method to run.'.
	self
		assert: (self summaryFrom: (self callToolNamed: 'test_run' withArguments: Dictionary new))
		equals: 'Invalid arguments for test_run. Name at least one package, class or method to run.'
]

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testTheCoverageToolRefusesInItsOwnName [

	self
		assert: (self summaryFrom: (self callToolNamed: 'test_coverage_run' withArguments: {
						  (#methods -> #( 'NotAMethodReference' )).
						  (#coverage -> { (#scope -> { (#classes -> #( 'MCPToolRunTestsRaiser' )) } asDictionary) } asDictionary) } asDictionary))
		equals:
		'Invalid arguments for test_coverage_run. methods: NotAMethodReference is not a method reference; write it as Class>>#selector.'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testTheSameFailureInSetUpAndTearDownIsOneLine [

	self
		assert: (self textFrom: (self runTests: { (#methods -> #( 'MCPToolRunTestsSharedFailureTarget>>#testOne' )) })) lines
		equals:
		#( 'Ran 1 test (0 passed). 1 error.' 'error MCPToolRunTestsSharedFailureTarget>>#testOne (Error): fixture broken, in MCPToolRunTestsRaiser>>fail' )
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testTheSummaryCountsEachKindOnceAndInGoodGrammar [

	| tool |
	tool := MCPToolRunTests new.
	self
		assert: (tool successSummaryForData: {
					 (#runCount -> 1).
					 (#passedCount -> 0).
					 (#errorCount -> 1) } asDictionary)
		equals: 'Ran 1 test (0 passed). 1 error.'.
	self
		assert: (tool successSummaryForData: {
					 (#runCount -> 4).
					 (#passedCount -> 1).
					 (#failureCount -> 2).
					 (#errorCount -> 1).
					 (#skippedCount -> 2) } asDictionary)
		equals: 'Ran 4 tests (1 passed). 2 failures, 1 error. 2 skipped.'.
	self
		assert: (tool successSummaryForData: {
					 (#runCount -> 0).
					 (#passedCount -> 0).
					 (#skippedCount -> 1) } asDictionary)
		equals: 'Ran 0 tests (0 passed). 1 skipped.'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testTheSummaryKeepsTheOpeningTheGraderReads [
	"An eval grader reads every answer that runs by this opening, a timeout's included."

	{
		{ (#classes -> #( 'MCPToolStructuredOutputTestTarget' )) }.
		{ (#classes -> #( 'MCPToolRunTestsBrokenFixtureTarget' )) }.
		{
			(#classes -> #( 'MCPToolStructuredOutputTestTarget' )).
			(#timeoutSeconds -> 0) }.
		{ (#packages -> #( 'MCP-Tests-Resources-Extensions' )) } } do: [ :arguments |
			| summary |
			summary := self summaryFrom: (self runTests: arguments).
			self assert: (summary matchesRegex: 'Ran \d+ tests? \(\d+ passed\).*') description: summary ]
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testTheTimeoutIsSaidOnce [

	| text |
	text := self textFrom: (self runTests: {
				         (#classes -> #( 'MCPToolStructuredOutputTestTarget' )).
				         (#timeoutSeconds -> 0) }).
	self assert: (text includesSubstring: 'notRun:') description: text.
	#( 'timedOut:' 'timeoutMilliseconds:' 'interrupted:' 'notRunCount:' ) do: [ :each |
		self deny: (text includesSubstring: each) description: text ]
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testTwoMessagesRunTogetherSayTheyAreOneMessage [
	"sorted:collect: was meant as sorted: then collect:, which the compile critique says, and so does the test that sends it. The message is not asserted: its wording differs before Pharo 12."

	| lines |
	lines := self issueLinesFrom:
		         (self runTests: { (#methods -> #( 'MCPToolRunTestsNotUnderstoodTarget>>#testRunsTwoMessagesTogether' )) }).
	self assert: lines size equals: 1.
	self assert:
		(lines first beginsWith: 'error MCPToolRunTestsNotUnderstoodTarget>>#testRunsTwoMessagesTogether (MessageNotUnderstood): ').
	self assert: (lines first endsWith:
			 '. sorted:collect: is one message. To send collect: to what sorted: answers, put the sorted: send in parentheses: (... sorted: ...) collect: ...')
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testWhatAPackageLeavesIsListedByClass [
	"A class none of whose cases ran or was lost is passed back whole, any other by the methods left."

	| broken command notRun package someFail testCases |
	command := MCPRunTestsCommand new.
	package := MCPTestSelectionSpec packageName: 'P'.
	someFail := (self fixtureNamed: 'MCPToolRunTestsSomeFailTarget') buildSuite tests.
	broken := (self fixtureNamed: 'MCPToolRunTestsBrokenFixtureTarget') buildSuite tests.
	testCases := someFail , broken.
	notRun := [ :uniqueTestCases :startIndex |
		          (command
			           notRunSelectionsFor: package
			           testCases: testCases
			           uniqueTestCases: uniqueTestCases
			           startingAt: startIndex) collect: [ :each | each displayName ] ].
	self assert: (notRun value: testCases value: 1) equals: #( 'P' ).
	self
		assert: (notRun value: testCases value: 2)
		equals:
		#( 'MCPToolRunTestsSomeFailTarget>>#testB' 'MCPToolRunTestsSomeFailTarget>>#testC' 'MCPToolRunTestsBrokenFixtureTarget' ).
	self assert: (notRun value: testCases value: 4) equals: #( 'MCPToolRunTestsBrokenFixtureTarget' ).
	self
		assert: (notRun value: (testCases copyWithout: broken first) value: 2)
		equals:
		#( 'MCPToolRunTestsSomeFailTarget>>#testB' 'MCPToolRunTestsSomeFailTarget>>#testC' 'MCPToolRunTestsBrokenFixtureTarget>>#testTwo' )
]
