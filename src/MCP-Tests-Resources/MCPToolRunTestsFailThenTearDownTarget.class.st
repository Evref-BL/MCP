"
Fixture test case used by test_run tests.
"
Class {
	#name : 'MCPToolRunTestsFailThenTearDownTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'running' }
MCPToolRunTestsFailThenTearDownTarget >> tearDown [
	"This is a fixture method; the error is intentional and exercised by MCP test-running tool tests."

	Error signal: 'tearDown broken'
]

{ #category : 'tests' }
MCPToolRunTestsFailThenTearDownTarget >> testFails [
	"This is a fixture test method; the failure is intentional and exercised by MCP test-running tool tests."

	self assert: false
]
