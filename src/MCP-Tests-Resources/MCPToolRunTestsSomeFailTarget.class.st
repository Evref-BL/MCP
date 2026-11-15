"
Fixture test case used by test_run tests.
"
Class {
	#name : 'MCPToolRunTestsSomeFailTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolRunTestsSomeFailTarget >> testA [
	"This is a fixture test method; the error is intentional and exercised by MCP test-running tool tests."

	MCPToolRunTestsRaiser new fail
]

{ #category : 'tests' }
MCPToolRunTestsSomeFailTarget >> testB [
	"This is a fixture test method; the error is intentional and exercised by MCP test-running tool tests."

	MCPToolRunTestsRaiser new fail
]

{ #category : 'tests' }
MCPToolRunTestsSomeFailTarget >> testC [
	"This is a fixture test method, intentionally exercised by MCP test-running tool tests."

	self assert: true
]
