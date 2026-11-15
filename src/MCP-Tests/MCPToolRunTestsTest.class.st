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

{ #category : 'tests - arguments' }
MCPToolRunTestsTest >> testAReferenceInAnyFormMethodGetAcceptsRuns [

	#( 'MCPToolRunTestsTimeoutTarget#testFastPass' 'MCPToolRunTestsTimeoutTarget >> testFastPass'
	   'MCPToolRunTestsTimeoutTarget class>>#testFastPass' ) do: [ :reference |
			| data |
			data := self dataFrom: (self callToolNamed: 'test_run' withArguments: { (#methods -> { reference }) } asDictionary).
			self assert: (data at: #runCount) = 1 description: reference.
			self assert: (data at: #passedCount) = 1 description: reference ]
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
