"
Fixture test case used by test_run tests.
"
Class {
	#name : 'MCPToolRunTestsLocationTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolRunTestsLocationTarget >> testComparesWithNil [
	"This is a fixture test method; the error is intentional and exercised by MCP test-running tool tests."

	MCPToolRunTestsRaiser new compareWithNil
]

{ #category : 'tests' }
MCPToolRunTestsLocationTarget >> testEqualityFails [
	"This is a fixture test method; the failure is intentional and exercised by MCP test-running tool tests."

	self assert: 1 equals: 2
]

{ #category : 'tests' }
MCPToolRunTestsLocationTarget >> testNilReceiver [
	"This is a fixture test method; the error is intentional and exercised by MCP test-running tool tests."

	MCPToolRunTestsRaiser new addToNil
]
