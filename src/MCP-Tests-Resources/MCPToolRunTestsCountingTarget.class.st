"
Fixture test case that counts the runs of its test, so a test_run test can tell whether a refused call ran anything.
"
Class {
	#name : 'MCPToolRunTestsCountingTarget',
	#superclass : 'TestCase',
	#classVars : [
		'Runs'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'running' }
MCPToolRunTestsCountingTarget class >> resetRuns [

	Runs := 0
]

{ #category : 'accessing' }
MCPToolRunTestsCountingTarget class >> runs [

	^ Runs ifNil: [ 0 ]
]

{ #category : 'tests' }
MCPToolRunTestsCountingTarget >> testCounts [
	"This is a fixture test method; it counts its runs so that MCP test-running tool tests can tell whether it ran."

	Runs := self class runs + 1.
	self assert: true
]
