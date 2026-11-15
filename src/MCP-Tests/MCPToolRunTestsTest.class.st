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

{ #category : 'private - fixtures' }
MCPToolRunTestsTest >> fixtureNamed: aClassName [
	"A fixture by its name, so that this class adds no reference to it."

	^ Smalltalk globals at: aClassName asSymbol
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

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAGlobalThatIsNotAClassIsRefusedByTheLookup [

	| result |
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> #( 'Transcript' )) } asDictionary.
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'NotAClass'.
	self assert: (self summaryFrom: result) equals: 'Transcript is a global variable, not a class.'
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

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAnInheritedTestMethodRuns [

	| data |
	data := self dataFrom: (self
			         callToolNamed: 'test_run'
			         withArguments: { (#methods -> #( 'MCPToolRunTestsInheritingTarget>>#testInherited' )) } asDictionary).
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 1
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
