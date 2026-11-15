"
Fixture test case used by test_run tests.
"
Class {
	#name : 'MCPToolRunTestsExpectedFailureTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolRunTestsExpectedFailureTarget >> testFailsAsExpected [
	"This is a fixture test method; the expected failure is intentional and exercised by MCP test-running tool tests."

	<expectedFailure>
	self assert: false
]

{ #category : 'tests' }
MCPToolRunTestsExpectedFailureTarget >> testPassesUnexpectedly [
	"This is a fixture test method; passing although marked as an expected failure is intentional and exercised by MCP test-running tool tests."

	<expectedFailure>
	self assert: true
]
