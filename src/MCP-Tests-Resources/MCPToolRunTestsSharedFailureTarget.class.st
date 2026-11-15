"
Fixture test case used by test_run tests.
"
Class {
	#name : 'MCPToolRunTestsSharedFailureTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'running' }
MCPToolRunTestsSharedFailureTarget >> setUp [
	"This is a fixture method; the error is intentional and exercised by MCP test-running tool tests."

	super setUp.
	MCPToolRunTestsRaiser new fail
]

{ #category : 'running' }
MCPToolRunTestsSharedFailureTarget >> tearDown [
	"This is a fixture method; the error is intentional and exercised by MCP test-running tool tests."

	MCPToolRunTestsRaiser new fail.
	super tearDown
]

{ #category : 'tests' }
MCPToolRunTestsSharedFailureTarget >> testOne [
	"This is a fixture test method, intentionally exercised by MCP test-running tool tests."

	self assert: true
]
