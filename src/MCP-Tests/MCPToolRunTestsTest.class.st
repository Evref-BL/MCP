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
	"What test_run's command answers, before the tool words it."

	| tool |
	tool := MCPToolRunTests new.
	^ (tool commandForRequest: (self parsedRequestForTool: tool arguments: someArguments asDictionary)) execute
]

{ #category : 'private - running' }
MCPToolRunTestsTest >> commandResultForClasses: classNames timeoutMilliseconds: milliseconds [
	"What test_run's command answers for a timeout finer than timeoutSeconds can say."

	| runTestsRequest tool |
	tool := MCPToolRunTests new.
	runTestsRequest := MCPRunTestsRequest new
		                   initializeTestRequests: (classNames collect: [ :each | MCPTestRunRequest className: each ] as: Array)
		                   timeoutMilliseconds: milliseconds
		                   operation: 'run'
		                   coverageRequest: nil.
	^ (tool commandForRequest: runTestsRequest) execute
]

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> fixtureNamed: aClassName [
	"A fixture by its name, so that this class adds no reference to it."

	^ Smalltalk globals at: aClassName asSymbol
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

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testABlankOnlyArgumentNamesNothingToActOn [

	self
		assertResult: (self callToolNamed: 'test_run' withArguments: { (#methods -> #( '  ' )) } asDictionary)
		refusesArgumentsSaying: 'methods names nothing to act on; give at least one value that is not blank.'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAClassNothingRefersToHasNoReferringTestClass [

	self assertEmpty:
		(MCPClassReferenceQuery forClass: (self fixtureNamed: 'MCPToolRunTestsUnreferencedTarget')) referringTestClasses
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAClassReadWithItsSideRunsTheClassTests [

	| data |
	data := self dataFrom:
		        (self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'MCPToolRunTestsTimeoutTarget class' )) } asDictionary).
	self assert: (data at: #runCount) equals: 2
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testAFailureInTheTestMethodRecordsItsStatement [

	| issue |
	issue := self onlyIssueOf: (self outcomesFor: { (#methods -> #( 'MCPToolRunTestsLocationTarget>>#testEqualityFails' )) }) first.
	self assert: (issue at: #message) equals: 'Got 1 instead of 2.'.
	self assert: (issue at: #statement) equals: 'self assert: 1 equals: 2'.
	self assertEmpty: (issue at: #locations).
	issue := self onlyIssueOf: (self outcomesFor: { (#methods -> #( 'MCPToolStructuredOutputTestTarget>>#testFails' )) }) first.
	self assert: (issue at: #statement) equals: 'self assert: false description: ''boom failure'''
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAGlobalThatIsNotAClassIsRefusedByTheLookup [

	| result |
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'Transcript' )) } asDictionary.
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'NotAClass'.
	self assert: (self summaryFrom: result) equals: 'Transcript is a global variable, not a class.'
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

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAMethodOfANonTestClassIsRefused [

	| summary |
	summary := self summaryFrom:
		           (self
			            callToolNamed: 'test_run'
			            withArguments: { (#methods -> #( 'MCPToolCoverageTarget>>#coveredMethod' )) } asDictionary).
	self
		assert: (summary beginsWith:
				 'MCPToolCoverageTarget>>#coveredMethod is not a test: MCPToolCoverageTarget is not a test class. Test classes that refer to it: ')
		description: summary
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

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testANonTestClassIsRefusedNamingTheTestClassesThatReferToIt [

	| error result summary |
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'MCPToolCoverageTarget' )) } asDictionary.
	summary := self summaryFrom: result.
	error := self errorFrom: result.
	self assert: (self resultIndicatesError: result).
	self assert: (error at: #errorCode) equals: 'NotATestClass'.
	self
		assert: (summary beginsWith: 'MCPToolCoverageTarget is not a test class. Test classes that refer to it: ')
		description: summary.
	self assert: (summary includesSubstring: 'MCPToolCoverageTargetTest') description: summary
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testANonTestClassNothingRefersToIsRefusedSayingSo [

	| result |
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'MCPToolRunTestsUnreferencedTarget' )) } asDictionary.
	self assert: (self resultIndicatesError: result).
	self
		assert: (self summaryFrom: result)
		equals: 'MCPToolRunTestsUnreferencedTarget is not a test class, and no test class refers to it.'
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testANotRunSelectionThatLostCasesIsListedByMethod [
	"The abstract class's suite holds the inheriting class's case, which the first selection already ran, so the abstract class is not passed back whole."

	| result |
	result := self
		          commandResultForClasses: #( 'MCPToolRunTestsInheritingTarget' 'MCPToolRunTestsAbstractTarget' )
		          timeoutMilliseconds: 200.
	self assert: result timedOut.
	self assertEmpty: result unrunClassNames.
	self assert: (result unrunMethodReferences includes: 'MCPToolRunTestsSlowInheritingTarget>>#testWaits').
	self assert: result interruption name equals: 'MCPToolRunTestsSlowInheritingTarget>>#testWaits'.
	self assert: result interruption location isNil.
	self assert: result notRunCount equals: 1
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
			| data |
			data := self dataFrom: (self callToolNamed: 'test_run' withArguments: { (#methods -> { reference }) } asDictionary).
			self assert: (data at: #runCount) = 1 description: reference.
			self assert: (data at: #passedCount) = 1 description: reference ]
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testARefusalNamesTheReferringTestClassesItSaid [

	| entry |
	entry := ((self errorFrom:
		           (self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'MCPToolCoverageTarget' )) } asDictionary)) at:
		          #notTests) first.
	self assert: (entry at: #selection) equals: 'MCPToolCoverageTarget'.
	self assert: (entry at: #testClasses) first equals: 'MCPToolCoverageTargetTest'.
	self assert: (entry at: #testClassCount) equals: (entry at: #testClasses) size
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

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testATestFailingInSetUpAndTearDownCountsOnce [

	| data outcomes result |
	data := self dataFrom:
		        (self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'MCPToolRunTestsBrokenFixtureTarget' )) } asDictionary).
	self assert: (data at: #runCount) equals: 2.
	self assert: (data at: #passedCount) equals: 0.
	result := self commandResultFor: { (#classes -> #( 'MCPToolRunTestsBrokenFixtureTarget' )) }.
	self assert: result runCount equals: 2.
	self assert: result errorCount equals: 2.
	self assert: result failureCount equals: 0.
	outcomes := result outcomes.
	self
		assert: (outcomes collect: [ :each | each name ])
		equals: #( 'MCPToolRunTestsBrokenFixtureTarget>>#testOne' 'MCPToolRunTestsBrokenFixtureTarget>>#testTwo' ).
	outcomes do: [ :each |
			| issue |
			issue := self onlyIssueOf: each.
			self assert: each outcome equals: 'error'.
			self assert: (issue at: #errorClass) equals: #MessageNotUnderstood.
			self
				assert: (issue at: #locations) asArray
				equals: #( 'MCPToolRunTestsBrokenFixtureTarget>>setUp' 'MCPToolRunTestsBrokenFixtureTarget>>tearDown' ) ]
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testATestThatFailsThenErrsInTearDownIsOneErroredTest [

	| failure error outcome result |
	result := self commandResultFor: { (#classes -> #( 'MCPToolRunTestsFailThenTearDownTarget' )) }.
	self assert: result runCount equals: 1.
	self assert: result errorCount equals: 1.
	self assert: result failureCount equals: 0.
	outcome := result outcomes first.
	self assert: outcome outcome equals: 'error'.
	failure := (outcome issuesOfKind: 'failure') first.
	error := (outcome issuesOfKind: 'error') first.
	self assert: (failure at: #message) equals: 'Assertion failed'.
	self assert: (failure at: #statement) equals: 'self assert: false'.
	self assertEmpty: (failure at: #locations).
	self assert: (error at: #message) equals: 'tearDown broken'.
	self assert: (error at: #locations) asArray equals: #( 'MCPToolRunTestsFailThenTearDownTarget>>tearDown' )
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testATestThatFinishesBeforeTheTimeoutIsNotInterrupted [

	| data |
	data := self dataFrom: (self callToolNamed: 'test_run' withArguments: {
				         (#methods -> #( 'MCPToolRunTestsTimeoutTarget>>#testFastPass' )).
				         (#timeoutSeconds -> 30) } asDictionary).
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 1.
	self deny: (data includesKey: #timedOut)
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

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testATimeLimitSaysWhichLimitItWas [

	| issue |
	issue := self onlyIssueOf: (self outcomesFor: { (#classes -> #( 'MCPToolRunTestsTimeLimitTarget' )) }) first.
	self assert: (issue at: #errorClass) equals: #TestTookTooMuchTime.
	self assert: (issue at: #message) equals: 'took longer than its time limit of 1 second'.
	self assertEmpty: (issue at: #locations)
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

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testAnErrorInTheTestMethodHasNoLocationNorStatement [

	| issue |
	issue := self onlyIssueOf: (self outcomesFor: { (#methods -> #( 'MCPToolStructuredOutputTestTarget>>#testErrors' )) }) first.
	self assert: (issue at: #message) equals: 'boom error'.
	self assertEmpty: (issue at: #locations).
	self deny: (issue includesKey: #statement)
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testAnErrorNamesTheMethodItCameFrom [

	| issue |
	issue := self onlyIssueOf: (self outcomesFor: { (#methods -> #( 'MCPToolRunTestsLocationTarget>>#testNilReceiver' )) }) first.
	self assert: (issue at: #errorClass) equals: #MessageNotUnderstood.
	self assert: (issue at: #locations) asArray equals: #( 'MCPToolRunTestsRaiser>>addToNil' ).
	self deny: (issue includesKey: #statement)
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAnInheritedTestMethodRuns [

	| data |
	data := self dataFrom: (self
			         callToolNamed: 'test_run'
			         withArguments: { (#methods -> #( 'MCPToolRunTestsInheritingTarget>>#testInherited' )) } asDictionary).
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 1
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testAnInterruptedTestIsNotCountedAndDoesNotDelayTheAnswer [
	"The fixture's tearDown waits 30 seconds and its class's time limit is 5: without the second the interrupted test gets for its tearDown, the answer would take 5 seconds."

	| milliseconds result |
	milliseconds := [ result := self commandResultForClasses: #( 'MCPToolRunTestsSlowTearDownTarget' ) timeoutMilliseconds: 200 ]
		                timeToRun asMilliSeconds.
	self assert: result timedOut.
	self assert: result runCount equals: 0.
	self assertEmpty: result outcomes.
	self assertEmpty: result errorDictionaries.
	self assert: result interruption name equals: 'MCPToolRunTestsSlowTearDownTarget>>#testWaits'.
	self assert: result interruption location equals: 'MCPToolRunTestsRaiser>>waitHalfASecond'.
	self assert: result unrunClassNames equals: #( 'MCPToolRunTestsSlowTearDownTarget' ).
	self assertEmpty: result unrunMethodReferences.
	self assert: result notRunCount equals: 1.
	self assert: result timeoutMilliseconds equals: 200.
	self
		assert: milliseconds < 3000
		description: [ String streamContents: [ :stream | stream << 'took ' << milliseconds printString << ' ms' ] ]
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testAnIssueTakesItsKindFromItsException [

	| outcome |
	outcome := (self outcomesFor: { (#classes -> #( 'MCPToolRunTestsSetUpErrorTarget' )) }) first.
	self assert: outcome outcome equals: 'error'.
	self
		assert: ((outcome issuesOfKind: 'error') collect: [ :each | (each at: #locations) asArray ])
		equals: #( #( 'MCPToolRunTestsRaiser>>fail' ) ).
	self
		assert: ((outcome issuesOfKind: 'failure') collect: [ :each | (each at: #locations) asArray ])
		equals: #( #( 'MCPToolRunTestsSetUpErrorTarget>>tearDown' ) )
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testAnUnexpectedPassFailsAndAnExpectedFailurePasses [

	| byName result |
	result := self commandResultFor: { (#classes -> #( 'MCPToolRunTestsExpectedFailureTarget' )) }.
	self assert: result runCount equals: 2.
	self assert: result passedCount equals: 1.
	self assert: result failureCount equals: 1.
	byName := (result outcomes collect: [ :each | each selector -> each ]) asDictionary.
	self assert: (byName at: 'testFailsAsExpected') outcome equals: 'passed'.
	self assertEmpty: (byName at: 'testFailsAsExpected') issues.
	self assert: (byName at: 'testPassesUnexpectedly') outcome equals: 'failure'.
	self
		assert: ((self onlyIssueOf: (byName at: 'testPassesUnexpectedly')) at: #message)
		equals: 'it passed, but it is marked <expectedFailure>'
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
		'MCPToolRunTestsUnreferencedTarget is not a test class, and no test class refers to it. MCPToolStructuredOutputTestTarget>>#setUp is not one of MCPToolStructuredOutputTestTarget''s tests. Name one of its test methods, or the class to run them all.'.
	self assert: notTests size equals: 2.
	self assert: notTests first equals: {
			(#selection -> 'MCPToolRunTestsUnreferencedTarget').
			(#class -> 'MCPToolRunTestsUnreferencedTarget').
			(#testClassCount -> 0) } asDictionary.
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

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testNoSelectionAsksForOne [

	self
		assertResult: (self callToolNamed: 'test_run' withArguments: { (#timeoutSeconds -> 5) } asDictionary)
		refusesArgumentsSaying: 'Name at least one package, class or method to run.'.
	self
		assert: (self summaryFrom: (self callToolNamed: 'test_run' withArguments: Dictionary new))
		equals: 'Invalid arguments for test_run. Name at least one package, class or method to run.'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testPastFiveReferringTestClassesTheRestAreCounted [

	| command names |
	command := MCPRunTestsCommand new.
	names := (1 to: 7) collect: [ :each | 'T' , each printString ].
	self
		assert: (command textForClassNamed: 'C' notATestClassReferredBy: names)
		equals: 'C is not a test class. Test classes that refer to it: T1, T2, T3, T4, T5, and 2 more.'.
	self
		assert: (command textForClassNamed: 'C' notATestClassReferredBy: (names first: 2))
		equals: 'C is not a test class. Test classes that refer to it: T1, T2.'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testReferringTestClassesComeMostReferringFirst [

	| referring |
	referring := (MCPClassReferenceQuery forClass: (self fixtureNamed: 'MCPToolCoverageTarget')) referringTestClasses collect: [
		             :each | each key name asString -> each value ].
	self assert: referring first equals: 'MCPToolCoverageTargetTest' -> 2.
	self assert: referring second equals: 'MCPToolStructuredOutputTest' -> 1
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

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testTheSameErrorRaisedTwiceInATestIsOneIssue [

	| issue outcomes |
	outcomes := self outcomesFor: { (#methods -> #( 'MCPToolRunTestsSharedFailureTarget>>#testOne' )) }.
	self assert: outcomes size equals: 1.
	issue := self onlyIssueOf: outcomes first.
	self assert: (issue at: #kind) equals: 'error'.
	self assert: (issue at: #errorClass) equals: #Error.
	self assert: (issue at: #message) equals: 'fixture broken'.
	self assert: (issue at: #locations) asArray equals: #( 'MCPToolRunTestsRaiser>>fail' )
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testWhatAPackageLeavesIsListedByClass [
	"A class none of whose cases ran or was lost is passed back whole, any other by the methods left."

	| broken command notRun package someFail testCases |
	command := MCPRunTestsCommand new.
	package := MCPValidatedTestRunRequest request: (MCPTestRunRequest packageName: 'P') testClass: nil.
	someFail := (self fixtureNamed: 'MCPToolRunTestsSomeFailTarget') buildSuite tests.
	broken := (self fixtureNamed: 'MCPToolRunTestsBrokenFixtureTarget') buildSuite tests.
	testCases := someFail , broken.
	notRun := [ :uniqueTestCases :startIndex |
		          (command
			           notRunRequestsForValidatedRequest: package
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
