"
Tests what test_run runs and says: which selections it refuses before anything runs, how each test is counted once, where an issue came from, and what a timeout leaves to run.

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
	"What test_run's operation answers for a timeout finer than timeoutSeconds can say, giving the test it interrupts the shortest time SUnit takes for its tearDown."

	^ (MCPRunTestsCommandTearingDownBriefly
		   selections: (classNames collect: [ :each | MCPTestSelectionSpec className: each ] as: Array)
		   timeoutMilliseconds: milliseconds) execute
]

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> createTestClassNamed: aClassName traits: aTraitCompositionOrNil [
	"A subclass of TestCase in the generated package, using aTraitCompositionOrNil when there is one."

	^ self withoutEpiceaDuring: [
			  | builder |
			  self packageOrganizer ensurePackage: self generatedPackageName.
			  builder := TestCase << aClassName asSymbol.
			  aTraitCompositionOrNil ifNotNil: [ builder traits: aTraitCompositionOrNil ].
			  builder package: self generatedPackageName.
			  builder tag: self generatedTagName.
			  builder install ]
]

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> createTraitNamed: aTraitName [
	"A trait in the generated package."

	^ self withoutEpiceaDuring: [
			  | builder |
			  self packageOrganizer ensurePackage: self generatedPackageName.
			  builder := Trait << aTraitName asSymbol.
			  builder package: self generatedPackageName.
			  builder tag: self generatedTagName.
			  builder install ]
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
MCPToolRunTestsTest >> removeClassesNamed: someClassNames [
	"Removes each class, and the binding its removal leaves in Undeclared, where a class later made under its name would take it over."

	someClassNames do: [ :each |
			self removeClassNamed: each.
			Undeclared removeKey: each asSymbol ifAbsent: [ nil ] ]
]

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> resetCountingFixture [

	(self classNamed: 'MCPToolRunTestsCountingTarget') resetRuns
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

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAHelperOfATraitIsRefusedNamingNoMethod [
	"A helper is no test in the classes that use its trait either, so naming it in one of them would be refused too: their tests are named instead."

	self
		assert: (self summaryFrom: (self runTests: { (#methods -> #( 'TMCPToolRunTestsTraitTarget>>#helperFromTheTrait' )) }))
		equals:
		'TMCPToolRunTestsTraitTarget>>#helperFromTheTrait is not a test: TMCPToolRunTestsTraitTarget is a trait, and its tests run in the test classes that use it: MCPToolRunTestsTraitOtherUserTarget and MCPToolRunTestsTraitUserTarget. None of them runs that method as a test: name one of their test methods instead, or one of them to run all its tests.'
]

{ #category : 'tests - outcomes' }
MCPToolRunTestsTest >> testALocationNamesTheMethodClassWhenItIsInherited [

	| context |
	context := Context
		           sender: nil
		           receiver: (self classNamed: 'MCPToolRunTestsInheritingTarget') new
		           method: TestCase >> #setUp
		           arguments: #(  ).
	self assert: (MCPStructuredTestResult locationTextOf: context) equals: 'MCPToolRunTestsInheritingTarget(TestCase)>>setUp'.
	context := Context
		           sender: nil
		           receiver: (self classNamed: 'MCPToolRunTestsInheritingTarget')
		           method: (self classNamed: 'MCPToolRunTestsAbstractTarget') class >> #isAbstract
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
	self
		assert: summary
		equals:
		'MCPToolCoverageTarget>>#coveredMethod is not a test: MCPToolCoverageTarget is a subclass of Object, and a test class subclasses TestCase. If MCPToolCoverageTarget is meant to hold tests, make TestCase its superclass with class_update {"name": "MCPToolCoverageTarget", "superclass": "TestCase"}.'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAMethodOfATraitIsNamedInATestClassThatRunsIt [
	"A class that uses a trait can leave one of its tests out: the method is named in the first class, by name, that runs it, and the answer says which ones do."

	[
		self
			createTestClassNamed: 'MCPToolRunTestsTraitExcludingTarget'
			traits: (self classNamed: 'TMCPToolRunTestsTraitTarget') - { #testFromTheTrait }.
		self
			assert: (self summaryFrom: (self runTests: { (#methods -> #( 'TMCPToolRunTestsTraitTarget>>#testFromTheTrait' )) }))
			equals:
			'TMCPToolRunTestsTraitTarget>>#testFromTheTrait is not a test: TMCPToolRunTestsTraitTarget is a trait, and its tests run in the test classes that use it: MCPToolRunTestsTraitExcludingTarget, MCPToolRunTestsTraitOtherUserTarget and MCPToolRunTestsTraitUserTarget. Only MCPToolRunTestsTraitOtherUserTarget and MCPToolRunTestsTraitUserTarget run that method as a test: name it in one of them instead, as MCPToolRunTestsTraitOtherUserTarget>>#testFromTheTrait.' ]
		ensure: [ self removeClassesNamed: #( 'MCPToolRunTestsTraitExcludingTarget' ) ]
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAMethodOfATraitIsRefusedNamingItInATestClassThatUsesIt [

	self
		assert: (self summaryFrom: (self runTests: { (#methods -> #( 'TMCPToolRunTestsTraitTarget>>#testFromTheTrait' )) }))
		equals:
		'TMCPToolRunTestsTraitTarget>>#testFromTheTrait is not a test: TMCPToolRunTestsTraitTarget is a trait, and its tests run in the test classes that use it: MCPToolRunTestsTraitOtherUserTarget and MCPToolRunTestsTraitUserTarget. Name the method in one of them instead, as MCPToolRunTestsTraitOtherUserTarget>>#testFromTheTrait.'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAMethodOfATraitItsOnlyTestClassLeavesOutIsRefusedNamingThatClass [
	"No class runs the method as a test, so none is named with it: the class's own tests are."

	[
		| trait |
		trait := self createTraitNamed: 'TMCPToolRunTestsTraitExcludedTarget'.
		self ensureMethodSource: 'testExcluded self assert: true' protocol: 'tests' on: trait.
		self createTestClassNamed: 'MCPToolRunTestsTraitExcludingTarget' traits: trait - { #testExcluded }.
		self
			assert: (self summaryFrom: (self runTests: { (#methods -> #( 'TMCPToolRunTestsTraitExcludedTarget>>#testExcluded' )) }))
			equals:
			'TMCPToolRunTestsTraitExcludedTarget>>#testExcluded is not a test: TMCPToolRunTestsTraitExcludedTarget is a trait, and its tests run in the test classes that use it: MCPToolRunTestsTraitExcludingTarget. MCPToolRunTestsTraitExcludingTarget does not run that method as a test: name one of its test methods instead, or MCPToolRunTestsTraitExcludingTarget to run them all.' ]
		ensure: [ self removeClassesNamed: #( 'MCPToolRunTestsTraitExcludingTarget' 'TMCPToolRunTestsTraitExcludedTarget' ) ]
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
	self
		assert: (self summaryFrom: result)
		equals:
		'MCPToolRunTestsUnreferencedTarget is not a test class: it is a subclass of Object, and a test class subclasses TestCase. If MCPToolRunTestsUnreferencedTarget is meant to hold tests, make TestCase its superclass with class_update {"name": "MCPToolRunTestsUnreferencedTarget", "superclass": "TestCase"}.'
]

{ #category : 'tests - timeouts' }
MCPToolRunTestsTest >> testANotRunSelectionThatLostCasesIsListedByMethod [
	"The abstract class's suite holds the inheriting class's case, which the first selection already ran, so the abstract class is not passed back whole. The request order is packages, classes, methods, so an earlier selection takes some of a class's cases only through an abstract class."

	| data notRun result |
	result := self
		          commandResultForClasses: #( 'MCPToolRunTestsInheritingTarget' 'MCPToolRunTestsAbstractTarget' )
		          timeoutMilliseconds: 100.
	data := result asDictionary.
	notRun := data at: #notRun.
	self assert: (data at: #timedOut).
	self deny: (notRun includesKey: #classes).
	self assert: ((notRun at: #methods) includes: 'MCPToolRunTestsSlowInheritingTarget>>#testWaits').
	self assert: (data at: #interrupted) equals: { (#test -> 'MCPToolRunTestsSlowInheritingTarget>>#testWaits') } asDictionary.
	self assert: (data at: #notRunCount) equals: 1
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testANotUnderstoodNoteNamesARemovedClassByItsOwnName [
	"A message not understood whose receiver's other side implements it gets a note that names that side. When the receiver is an instance of a removed class, the note names the class by its own name, as the message does, not by the one Pharo gives it on removal."

	| classNames line lines |
	classNames := #( 'MCPToolRunTestsRemovedTargetTest' 'MCPToolRunTestsRemovedTarget' ).
	[
		self ensureMethodSource: 'buildRemoved ^ self new' protocol: 'instance creation' on: (self
				 createClassNamed: 'MCPToolRunTestsRemovedTarget'
				 superclassName: 'Object'
				 slots: #(  )
				 classSlots: #(  )) classSide.
		self
			ensureMethodSource: 'testSendsAClassMessageToAnInstance MCPToolRunTestsRemovedTarget new buildRemoved'
			protocol: 'tests'
			on: (self createTestClassNamed: 'MCPToolRunTestsRemovedTargetTest' traits: nil).
		self removeClassNamed: 'MCPToolRunTestsRemovedTarget'.
		lines := self issueLinesFrom:
			         (self runTests: { (#methods -> #( 'MCPToolRunTestsRemovedTargetTest>>#testSendsAClassMessageToAnInstance' )) }).
		self assert: lines size equals: 1.
		line := lines first.
		self deny: (line includesSubstring: 'AnObsolete') description: line.
		self
			assert: (line includesSubstring:
					 '; MCPToolRunTestsRemovedTarget was removed. MCPToolRunTestsRemovedTarget itself understands buildRemoved')
			description: line ] ensure: [ self removeClassesNamed: classNames ]
]

{ #category : 'tests - selections without tests' }
MCPToolRunTestsTest >> testAPackageWithoutTestClassesBesideOthersIsOnlyNamed [

	| count |
	count := (self classNamed: 'MCPToolRunTestsPackageTarget') testSelectors size.
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
	self assert: (self classNamed: 'MCPToolRunTestsCountingTarget') runs equals: 0
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
MCPToolRunTestsTest >> testASkipWithoutAReasonSaysNone [
	"self skip gives no reason, and the answer makes none up."

	[
		self
			ensureMethodSource: 'testSkipsWithoutAReason self skip'
			protocol: 'tests'
			on: (self createTestClassNamed: 'MCPToolRunTestsSkippingTarget' traits: nil).
		self
			assert:
			(self issueLinesFrom: (self runTests: { (#methods -> #( 'MCPToolRunTestsSkippingTarget>>#testSkipsWithoutAReason' )) }))
			equals: #( 'skipped MCPToolRunTestsSkippingTarget>>#testSkipsWithoutAReason' ) ] ensure: [
		self removeClassesNamed: #( 'MCPToolRunTestsSkippingTarget' ) ]
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
	result := MCPRunTestsResult outcomes: #(  ) timedOut: false unrunTests: #(  ).
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
MCPToolRunTestsTest >> testATestFromATraitThatStillHoldsTheRemovedCopyNamesTheTraitsMethodToCompile [
	"A test a class gets from a trait is the trait's method: compiling the class's copy would add a method of the class's own, and leave the trait, and the other classes that use it, holding the removed copy. Compiling the trait's method again is enough."

	self
		withRemovedClasses: #( 'MCPToolRunTestsRemovedTarget' )
		traitMethods: #( 'testFromTheTrait self assert: MCPToolRunTestsRemovedTarget new notNil' )
		testMethods: #(  )
		do: [
				Undeclared removeKey: #MCPToolRunTestsRemovedTarget ifAbsent: [ nil ].
				self
					createClassNamed: 'MCPToolRunTestsRemovedTarget'
					superclassName: 'Object'
					slots: #(  )
					classSlots: #(  ).
				self
					assert: (self summaryFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsRemovedTargetTest' )) }))
					equals:
					'Ran 1 test (1 passed). MCPToolRunTestsRemovedTargetTest>>#testFromTheTrait refers to MCPToolRunTestsRemovedTarget, a removed class, so it ran the obsolete copy of MCPToolRunTestsRemovedTarget. MCPToolRunTestsRemovedTarget exists again, but TMCPToolRunTestsRemovedTargetTest>>#testFromTheTrait still refers to its removed copy: compile that method again with method_compile, unchanged, and it will refer to the current MCPToolRunTestsRemovedTarget.'.
				self withoutEpiceaDuring: [
						(self classNamed: 'TMCPToolRunTestsRemovedTargetTest')
							compile: 'testFromTheTrait self assert: MCPToolRunTestsRemovedTarget new notNil'
							classified: 'tests' ].
				self
					assert: (self summaryFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsRemovedTargetTest' )) }))
					equals: 'Ran 1 test (1 passed).' ]
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testATestPastItsTimeLimitSaysSo [

	self
		assert: (self issueLinesFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsTimeLimitTarget' )) }))
		equals:
		#( 'error MCPToolRunTestsTimeLimitTarget>>#testWaitsTooLong (TestTookTooMuchTime): took longer than its time limit of 100 milliseconds' )
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

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testATestThatRefersToARemovedClassSaysSo [
	"A removed class's obsolete copy stays in the methods that referred to it, so the tests that refer to it still run, and can pass."

	self withRemovedClassDo: [
			self
				assert: (self summaryFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsRemovedTargetTest' )) }))
				equals:
				'Ran 2 tests (1 passed). 1 error. MCPToolRunTestsRemovedTargetTest>>#testBreaks and MCPToolRunTestsRemovedTargetTest>>#testPasses refer to MCPToolRunTestsRemovedTarget, a removed class, so they ran the obsolete copy of MCPToolRunTestsRemovedTarget. Create MCPToolRunTestsRemovedTarget again with class_create, or change the tests.' ]
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testATestThatStillHoldsTheRemovedCopyOfAClassMadeAgainNamesTheMethodsToCompile [
	"A class renamed to a removed one's name gets a binding of its own, as does one made under that name once the removed one's binding has left Undeclared: the methods that named the removed class keep its obsolete copy until they are compiled again, and a references search finds only the new class's references."

	self withRemovedClassDo: [
			Undeclared removeKey: #MCPToolRunTestsRemovedTarget ifAbsent: [ nil ].
			self
				createClassNamed: 'MCPToolRunTestsRemovedTarget'
				superclassName: 'Object'
				slots: #(  )
				classSlots: #(  ).
			self
				assert: (self summaryFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsRemovedTargetTest' )) }))
				equals:
				'Ran 2 tests (1 passed). 1 error. MCPToolRunTestsRemovedTargetTest>>#testBreaks and MCPToolRunTestsRemovedTargetTest>>#testPasses refer to MCPToolRunTestsRemovedTarget, a removed class, so they ran the obsolete copy of MCPToolRunTestsRemovedTarget. MCPToolRunTestsRemovedTarget exists again, but MCPToolRunTestsRemovedTargetTest>>#testBreaks and MCPToolRunTestsRemovedTargetTest>>#removedInstance still refer to its removed copy: compile those methods again with method_compile, unchanged, and they will refer to the current MCPToolRunTestsRemovedTarget.' ]
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

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testATraitIsRefusedNamingTheTestClassesThatRunItsTests [
	"A trait has no superclass to set: its tests run in the test classes that use it."

	| result |
	result := self runTests: { (#classes -> #( 'TMCPToolRunTestsTraitTarget' )) }.
	self assert: (self resultIndicatesError: result).
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'NotATestClass'.
	self
		assert: (self summaryFrom: result)
		equals:
		'TMCPToolRunTestsTraitTarget is not a test class: it is a trait, and its tests run in the test classes that use it: MCPToolRunTestsTraitOtherUserTarget and MCPToolRunTestsTraitUserTarget. Name one of them instead.'
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testATraitNoTestClassUsesIsRefusedSayingSo [
	"TMCPToolMethodSearchFixture is method_search's fixture: classes use it, and none of them is a test class."

	self
		assert: (self summaryFrom: (self runTests: { (#classes -> #( 'TMCPToolMethodSearchFixture' )) }))
		equals:
		'TMCPToolMethodSearchFixture is not a test class: it is a trait, and no test class uses it. A trait''s tests run in the test classes that use it.'
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAnErrorInAKernelMethodNamesTheCodeThatCalledIt [
	"Integer's comparison is where Pharo noticed the error, not where it was made: the line also names the code under test that called it, at the line it was running. The message is not asserted, since its wording differs between Pharo versions."

	| lines |
	lines := self issueLinesFrom: (self runTests: { (#methods -> #( 'MCPToolRunTestsLocationTarget>>#testComparesWithNil' )) }).
	self assert: lines size equals: 1.
	self
		assert:
		(lines first endsWith: ', called from MCPToolRunTestsRaiser>>compareWithNil at line 4: #( 1 ) do: [ :each | each > nil ]')
		description: lines first
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
	"The fixture's tearDown waits 30 seconds and its class's time limit is 5: without the short time the interrupted test gets for its tearDown, the answer would take 5 seconds."

	| data milliseconds result |
	milliseconds := [ result := self commandResultForClasses: #( 'MCPToolRunTestsSlowTearDownTarget' ) timeoutMilliseconds: 100 ]
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
	self assert: (data at: #timeoutMilliseconds) equals: 100.
	self
		assert: (self summaryForResult: result)
		equals:
		'Ran 0 tests (0 passed). Timed out after 100 milliseconds, during MCPToolRunTestsSlowTearDownTarget>>#testWaits, in MCPToolRunTestsRaiser>>waitHalfASecond. 1 test not run, listed below as test_run arguments.'.
	self
		assert: milliseconds < 3000
		description: [ String streamContents: [ :stream | stream << 'took ' << milliseconds printString << ' ms' ] ]
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAnIssueNamesARemovedClassByItsOwnName [
	"Pharo renames a class it removes AnObsolete followed by its name. The message is not asserted whole, since its wording differs between Pharo versions."

	self withRemovedClassDo: [
			| line lines |
			lines := self issueLinesFrom: (self runTests: { (#methods -> #( 'MCPToolRunTestsRemovedTargetTest>>#testBreaks' )) }).
			self assert: lines size equals: 1.
			line := lines first.
			self deny: (line includesSubstring: 'AnObsolete') description: line.
			self
				assert: (line endsWith: ', in MCPToolRunTestsRemovedTarget>>breaks; MCPToolRunTestsRemovedTarget was removed')
				description: line ]
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testAnIssueNamesARemovedClassWithItsOwnArticleButNotInAStringOrASymbol [
	"Pharo prints an instance of a removed ZooLion as an AnObsoleteZooLion, and ZooLion's own name takes a. A name in a string or a symbol, quoted with its article or without, is what the code compared or printed, not a class that ran."

	| names |
	names := OrderedCollection new.
	self
		assert: (MCPStructuredTestResult
				 textNamingRemovedClassesIn:
				 'Got an AnObsoleteZooLion instead of #AnObsoleteZooOwl. An AnObsoleteAnObsoleteZooEmu named ''AnObsoleteZooElk'' printed ''an AnObsoleteZooYak'''
				 into: names)
		equals: 'Got a ZooLion instead of #AnObsoleteZooOwl. A ZooEmu named ''AnObsoleteZooElk'' printed ''an AnObsoleteZooYak'''.
	self assert: names asArray equals: #( 'ZooLion' 'ZooEmu' )
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
MCPToolRunTestsTest >> testClassesMadeAgainThatATestStillHoldsShareOneSentence [
	"Each method that still holds a removed copy is named once, however many of the classes made again it refers to."

	self
		withRemovedClasses: #( 'MCPToolRunTestsRemovedTarget' 'MCPToolRunTestsRemovedOtherTarget' )
		testMethods: #( 'testBoth self assert: { MCPToolRunTestsRemovedTarget. MCPToolRunTestsRemovedOtherTarget } size equals: 2' )
		do: [
				#( 'MCPToolRunTestsRemovedTarget' 'MCPToolRunTestsRemovedOtherTarget' ) do: [ :each |
						Undeclared removeKey: each asSymbol ifAbsent: [ nil ].
						self
							createClassNamed: each
							superclassName: 'Object'
							slots: #(  )
							classSlots: #(  ) ].
				self
					assert: (self summaryFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsRemovedTargetTest' )) }))
					equals:
					'Ran 1 test (1 passed). MCPToolRunTestsRemovedTargetTest>>#testBoth refers to MCPToolRunTestsRemovedOtherTarget and MCPToolRunTestsRemovedTarget, removed classes, so it ran the obsolete copies of those classes. MCPToolRunTestsRemovedOtherTarget and MCPToolRunTestsRemovedTarget exist again, but MCPToolRunTestsRemovedTargetTest>>#testBoth still refers to their removed copies: compile that method again with method_compile, unchanged, and it will refer to the current MCPToolRunTestsRemovedOtherTarget and MCPToolRunTestsRemovedTarget.' ]
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
		'MCPToolRunTestsUnreferencedTarget is not a test class: it is a subclass of Object, and a test class subclasses TestCase. If MCPToolRunTestsUnreferencedTarget is meant to hold tests, make TestCase its superclass with class_update {"name": "MCPToolRunTestsUnreferencedTarget", "superclass": "TestCase"}. MCPToolStructuredOutputTestTarget>>#setUp is not one of MCPToolStructuredOutputTestTarget''s tests. Name one of its test methods, or the class to run them all.'.
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

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestClassReturnsStructuredIssues [

	| data error errorReference failure failureReference fixtureClassName result skippedReference |
	fixtureClassName := 'MCPToolStructuredOutputTestTarget'.
	skippedReference := 'MCPToolStructuredOutputTestTarget>>#testSkips'.
	failureReference := 'MCPToolStructuredOutputTestTarget>>#testFails'.
	errorReference := 'MCPToolStructuredOutputTestTarget>>#testErrors'.
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> { fixtureClassName }) } asDictionary.
	data := self dataFrom: result.
	self assert: (self summaryFrom: result) equals: 'Ran 3 tests (1 passed). 1 failure, 1 error. 1 skipped.'.
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #passedCount) equals: 1.
	failure := (data at: #failures) first.
	error := (data at: #errors) first.
	self assert: (data at: #skipped) equals: { {
			(#tests -> { skippedReference }).
			(#reason -> 'skip probe') } asDictionary }.
	self assert: (failure at: #tests) equals: { failureReference }.
	self assert: ((failure at: #message) includesSubstring: 'boom failure').
	self assert: (error at: #tests) equals: { errorReference }.
	self assert: (error at: #errorClass) equals: 'Error'.
	self assert: ((error at: #message) includesSubstring: 'boom error').
	self deny: (data includesKey: #results).
	self deny: (data includesKey: #issues)
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestMethodReturnsStructuredIssues [

	| data failure failureReference result |
	failureReference := 'MCPToolStructuredOutputTestTarget>>#testFails'.
	result := self callToolNamed: 'test_run' withArguments: { (#methods -> { failureReference }) } asDictionary.
	data := self dataFrom: result.
	failure := (data at: #failures) first.
	self assert: (self summaryFrom: result) equals: 'Ran 1 test (0 passed). 1 failure.'.
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 0.
	self assert: (data at: #failures) size equals: 1.
	self assert: (failure at: #tests) equals: { failureReference }.
	self assert: ((failure at: #message) includesSubstring: 'boom failure').
	self deny: (data includesKey: #results).
	self deny: (data includesKey: #skipped).
	self deny: (data includesKey: #errors)
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsDeduplicatesConcreteCasesAcrossSelections [

	| data failureReference fixtureClassName result |
	fixtureClassName := 'MCPToolStructuredOutputTestTarget'.
	failureReference := 'MCPToolStructuredOutputTestTarget>>#testFails'.
	result := self callToolNamed: 'test_run' withArguments: {
			          (#classes -> { fixtureClassName }).
			          (#methods -> { failureReference }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #passedCount) equals: 1.
	self assert: (data at: #skipped) size equals: 1.
	self assert: (data at: #failures) size equals: 1.
	self assert: (data at: #errors) size equals: 1
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsDeduplicatesUnrunCasesAcrossSelections [

	| data failureReference fixtureClassName result |
	fixtureClassName := 'MCPToolStructuredOutputTestTarget'.
	failureReference := 'MCPToolStructuredOutputTestTarget>>#testFails'.
	result := self callToolNamed: 'test_run' withArguments: {
			          (#classes -> { fixtureClassName }).
			          (#methods -> { failureReference }).
			          (#timeoutSeconds -> 0) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #timedOut) equals: true.
	self assert: (data at: #runCount) equals: 0.
	self assert: (data at: #passedCount) equals: 0.
	self assert: ((data at: #notRun) at: #classes) equals: { fixtureClassName }.
	self deny: ((data at: #notRun) includesKey: #methods).
	self deny: (data includesKey: #results).
	self
		assert: (self summaryFrom: result)
		equals: 'Ran 0 tests (0 passed). timeoutSeconds is 0, so nothing ran; 4 tests not run, listed below as test_run arguments.'
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsHasAccurateNameAndSchema [

	| inputPropertyNames tool |
	tool := MCPToolRunTests new.
	self assert: tool name equals: 'test_run'.
	self assert: (tool inputSchema required ifNil: [ #(  ) ]) isEmpty.
	inputPropertyNames := tool inputSchema properties collect: [ :each | each name ].
	self assert: inputPropertyNames asSet equals: #( 'packages' 'classes' 'methods' 'timeoutSeconds' ) asSet
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsKeepsPackagesAsPackageSelections [

	| command request selections testCases tool |
	tool := MCPToolRunTests new.
	request := tool requestFromToolCallArguments: { (#packages -> #( 'MCP-Tests' )) } asDictionary.
	command := tool operationFor: request.
	selections := command selections.
	self assert: selections size equals: 1.
	self assert: selections first isPackageSelection.
	self assert: selections first packageName equals: 'MCP-Tests'.
	self assert: selections first displayName equals: 'MCP-Tests'.
	self assert: selections first className equals: nil.
	self assert: selections first testMethodName equals: nil.
	command validateSelections.
	testCases := command testCasesFor: selections first.
	self assert: testCases isNotEmpty.
	self assert: (testCases noneSatisfy: [ :each | each class isAbstract ])
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsLetsNotificationsUseTheirDefaultAction [

	| data result |
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'MCPToolNotificationTargetTest' )) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 1
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsParameterizedMethodFailureIncludesCaseDetails [

	| data issue result |
	result := self
		          callToolNamed: 'test_run'
		          withArguments: { (#methods -> #( 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16' )) } asDictionary.
	data := self dataFrom: result.
	issue := (data at: #failures) first.
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #passedCount) equals: 2.
	self assert: (data at: #failures) size equals: 1.
	self
		assert: (issue at: #tests)
		equals: #( 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16 with #encoding->''UTF-16''' ).
	self deny: (issue includesKey: #parameters).
	self deny: (issue includesKey: #testName).
	self deny: (issue includesKey: #testCaseName).
	self assert: ((self textFrom: result) includesSubstring:
			 'with #encoding->''UTF-16'': UTF-16 probe failure, at self deny: encoding = ''UTF-16'' description: ''UTF-16 probe failure''')
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsParseErrorReturnsStructuredToolError [

	self
		assertResult: (self callToolNamed: 'test_run' withArguments: { (#methods -> #( 'NotAMethodReference' )) } asDictionary)
		refusesArgumentsSaying: 'methods: NotAMethodReference is not a method reference; write it as Class>>#selector.'
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsParsesCompactSelections [

	| command fixtureClassName request selections testMethodReference tool |
	tool := MCPToolRunTests new.
	fixtureClassName := 'MCPToolStructuredOutputTestTarget'.
	testMethodReference := 'MCPToolStructuredOutputTestTarget>>#testPasses'.
	request := tool requestFromToolCallArguments: {
			           (#classes -> { self class name asString }).
			           (#methods -> { testMethodReference }) } asDictionary.
	command := tool operationFor: request.
	command validateSelections.
	selections := command selections.
	self assert: selections size equals: 2.
	self assert: selections first className equals: self class name asString.
	self assert: selections first testMethodName equals: nil.
	self assert: selections second className equals: fixtureClassName.
	self assert: selections second testMethodName equals: #testPasses asString.
	self assert: selections second displayName equals: testMethodReference.
	self assert: selections first testClass equals: self class
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsParsesTimeoutSeconds [

	| request tool |
	tool := MCPToolRunTests new.
	request := tool requestFromToolCallArguments: {
			           (#classes -> #( 'MCPToolContractsTest' )).
			           (#timeoutSeconds -> 2) } asDictionary.
	self assert: (tool operationFor: request) timeoutMilliseconds equals: 2000
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsSkippedMethodReportsCompactList [

	| data result skippedReference |
	skippedReference := 'MCPToolStructuredOutputTestTarget>>#testSkips'.
	result := self callToolNamed: 'test_run' withArguments: { (#methods -> { skippedReference }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #runCount) equals: 0.
	self assert: (data at: #passedCount) equals: 0.
	self assert: (data at: #skipped) equals: { {
			(#tests -> { skippedReference }).
			(#reason -> 'skip probe') } asDictionary }.
	self deny: (data includesKey: #failures).
	self deny: (data includesKey: #errors).
	self assert: ((self textFrom: result) includesSubstring: 'skipped MCPToolStructuredOutputTestTarget>>#testSkips: skip probe')
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsSuccessfulResultHasExpectedShape [

	| data result testMethodReference |
	testMethodReference := 'MCPToolStructuredOutputTestTarget>>#testPasses'.
	result := self callToolNamed: 'test_run' withArguments: { (#methods -> { testMethodReference }) } asDictionary.
	data := self dataFrom: result.
	self assert: data equals: {
			(#runCount -> 1).
			(#passedCount -> 1) } asDictionary
]

{ #category : 'tests' }
MCPToolRunTestsTest >> testRunTestsTimeoutReturnsPartialResultsAndUnrunSelectionsCanResume [

	| data expectedRunCount notRun request resumedData resumedResult result tool |
	tool := MCPToolRunTests new.
	expectedRunCount := 1 + (self classNamed: 'MCPToolCoverageTargetTest') testSelectors size
	                    + (self classNamed: 'MCPToolRunTestsPackageTarget') testSelectors size.
	result := (MCPRunTestsCommand
		           selections: {
				           (MCPTestSelectionSpec className: 'MCPToolRunTestsTimeoutTarget').
				           (MCPTestSelectionSpec className: 'MCPToolCoverageTargetTest').
				           (MCPTestSelectionSpec packageName: 'MCP-Tests-RunResources') }
		           timeoutMilliseconds: 100) execute.
	data := result asDictionary.
	notRun := data at: #notRun.
	self assert: (data at: #timedOut).
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 1.
	self assert: (data at: #interrupted) equals: { (#test -> 'MCPToolRunTestsTimeoutTarget>>#testSlowPass') } asDictionary.
	self assert: (notRun at: #methods) equals: #( 'MCPToolRunTestsTimeoutTarget>>#testSlowPass' ).
	self assert: (notRun at: #classes) equals: #( 'MCPToolCoverageTargetTest' ).
	self assert: (notRun at: #packages) equals: #( 'MCP-Tests-RunResources' ).
	self assert: (tool successSummaryForData: data) equals: (String streamContents: [ :stream |
				 stream
					 << 'Ran 1 test (1 passed). Timed out after 100 milliseconds, during MCPToolRunTestsTimeoutTarget>>#testSlowPass. ';
					 print: expectedRunCount;
					 << ' tests not run, listed below as test_run arguments.' ]).
	request := Dictionary new
		           at: #methods put: (notRun at: #methods);
		           at: #classes put: (notRun at: #classes);
		           at: #packages put: (notRun at: #packages);
		           at: #timeoutSeconds put: 30;
		           yourself.
	resumedResult := self callToolNamed: 'test_run' withArguments: request.
	resumedData := self dataFrom: resumedResult.
	self deny: (resumedData includesKey: #timedOut).
	self assert: (resumedData at: #passedCount) equals: (resumedData at: #runCount).
	self assert: (resumedData at: #runCount) equals: expectedRunCount
]

{ #category : 'tests - answers' }
MCPToolRunTestsTest >> testTestsThatReferToTheSameRemovedClassesInAnyOrderShareOneSentence [
	"Each test's code names the removed classes in its own order: the answer groups the tests by the classes, whatever that order."

	self
		withRemovedClasses: #( 'MCPToolRunTestsRemovedTarget' 'MCPToolRunTestsRemovedOtherTarget' )
		testMethods:
			#( 'testOtherFirst self assert: { MCPToolRunTestsRemovedOtherTarget. MCPToolRunTestsRemovedTarget } size equals: 2'
			   'testTargetFirst self assert: { MCPToolRunTestsRemovedTarget. MCPToolRunTestsRemovedOtherTarget } size equals: 2' )
		do: [
				self
					assert: (self summaryFrom: (self runTests: { (#classes -> #( 'MCPToolRunTestsRemovedTargetTest' )) }))
					equals:
					'Ran 2 tests (2 passed). MCPToolRunTestsRemovedTargetTest>>#testOtherFirst and MCPToolRunTestsRemovedTargetTest>>#testTargetFirst refer to MCPToolRunTestsRemovedOtherTarget and MCPToolRunTestsRemovedTarget, removed classes, so they ran the obsolete copies of those classes. Create MCPToolRunTestsRemovedOtherTarget and MCPToolRunTestsRemovedTarget again with class_create, or change the tests.' ]
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
	someFail := (self classNamed: 'MCPToolRunTestsSomeFailTarget') buildSuite tests.
	broken := (self classNamed: 'MCPToolRunTestsBrokenFixtureTarget') buildSuite tests.
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

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> withRemovedClassDo: aBlock [
	"Runs aBlock while MCPToolRunTestsRemovedTargetTest's tests refer to MCPToolRunTestsRemovedTarget, a class removed since, testPasses through a helper of its class. The removed class's breaks sends a message it does not understand."

	self
		withRemovedClasses: #( 'MCPToolRunTestsRemovedTarget' )
		testMethods: #( 'removedInstance ^ MCPToolRunTestsRemovedTarget new' 'testBreaks MCPToolRunTestsRemovedTarget new breaks'
			   'testPasses self assert: self removedInstance notNil' )
		do: aBlock
]

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> withRemovedClasses: someClassNames testMethods: someSources do: aBlock [
	"Runs aBlock while MCPToolRunTestsRemovedTargetTest, holding the methods someSources define, refers to the classes someClassNames name, removed since."

	self
		withRemovedClasses: someClassNames
		traitMethods: #(  )
		testMethods: someSources
		do: aBlock
]

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> withRemovedClasses: someClassNames traitMethods: someTraitSources testMethods: someSources do: aBlock [
	"Runs aBlock while MCPToolRunTestsRemovedTargetTest, holding the methods someSources define, and using TMCPToolRunTestsRemovedTargetTest, holding those someTraitSources define, when there are any, refers to the classes someClassNames name, removed since. Each removed class's breaks sends a message it does not understand."

	| classNames |
	classNames := #( 'MCPToolRunTestsRemovedTargetTest' 'TMCPToolRunTestsRemovedTargetTest' ) , someClassNames.
	[
		| testClass trait |
		someClassNames do: [ :each |
				self ensureMethodSource: 'breaks ^ self notUnderstoodByTheRemovedClass' protocol: 'fixture' on: (self
						 createClassNamed: each
						 superclassName: 'Object'
						 slots: #(  )
						 classSlots: #(  )) ].
		someTraitSources ifNotEmpty: [
				trait := self createTraitNamed: 'TMCPToolRunTestsRemovedTargetTest'.
				someTraitSources do: [ :each | self ensureMethodSource: each protocol: 'tests' on: trait ] ].
		testClass := self createTestClassNamed: 'MCPToolRunTestsRemovedTargetTest' traits: trait.
		someSources do: [ :each |
				self
					ensureMethodSource: each
					protocol: ((each beginsWith: 'test')
							 ifTrue: [ 'tests' ]
							 ifFalse: [ 'fixture' ])
					on: testClass ].
		someClassNames do: [ :each | self removeClassNamed: each ].
		aBlock value ] ensure: [ self removeClassesNamed: classNames ]
]
