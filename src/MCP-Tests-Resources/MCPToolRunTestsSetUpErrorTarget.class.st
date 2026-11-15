"
Fixture test case used by test_run tests.
"
Class {
	#name : 'MCPToolRunTestsSetUpErrorTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'running' }
MCPToolRunTestsSetUpErrorTarget >> setUp [
	"This is a fixture method; the error is intentional and exercised by MCP test-running tool tests."

	super setUp.
	MCPToolRunTestsRaiser new fail
]

{ #category : 'running' }
MCPToolRunTestsSetUpErrorTarget >> tearDown [
	"This is a fixture method; the failure is intentional and exercised by MCP test-running tool tests."

	self assert: false
]

{ #category : 'tests' }
MCPToolRunTestsSetUpErrorTarget >> testOne [
	"This is a fixture test method, intentionally exercised by MCP test-running tool tests."

	self assert: true
]
