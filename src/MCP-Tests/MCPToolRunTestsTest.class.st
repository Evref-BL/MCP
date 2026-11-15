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

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testAClassNothingRefersToHasNoReferringTestClass [

	self assertEmpty:
		(MCPClassReferenceQuery forClass: (self fixtureNamed: 'MCPToolRunTestsUnreferencedTarget')) referringTestClasses
]

{ #category : 'tests - refusals' }
MCPToolRunTestsTest >> testReferringTestClassesComeMostReferringFirst [

	| referring |
	referring := (MCPClassReferenceQuery forClass: (self fixtureNamed: 'MCPToolCoverageTarget')) referringTestClasses collect: [
		             :each | each key name asString -> each value ].
	self assert: referring first equals: 'MCPToolCoverageTargetTest' -> 2.
	self assert: referring second equals: 'MCPToolStructuredOutputTest' -> 1
]
