"
Fixture test case used by test_run tests.
"
Class {
	#name : 'MCPToolRunTestsSlowTearDownTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'accessing' }
MCPToolRunTestsSlowTearDownTarget class >> defaultTimeLimit [

	^ 5 seconds
]

{ #category : 'running' }
MCPToolRunTestsSlowTearDownTarget >> tearDown [
	"This is a fixture method; the long delay is intentional, so that test_run must cut the time a timed-out test has left. It is bounded, so a failure cannot wedge an image."

	(Delay forSeconds: 30) wait
]

{ #category : 'tests' }
MCPToolRunTestsSlowTearDownTarget >> testWaits [
	"This is a fixture test method; the delay is intentional and exercised by MCP test-running timeout tests."

	MCPToolRunTestsRaiser new waitHalfASecond
]
