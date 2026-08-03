"
Fixture class used by structured output tests.
"
Class {
	#name : 'MCPToolStructuredOutputTestTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolStructuredOutputTestTarget >> testErrors [
	"This is a fixture test method; the error is intentional and exercised by MCP test-running tool tests."

	Error signal: 'boom error'
]

{ #category : 'tests' }
MCPToolStructuredOutputTestTarget >> testFails [
	"This is a fixture test method; the failure is intentional and exercised by MCP test-running tool tests."

	self assert: false description: 'boom failure'
]

{ #category : 'tests' }
MCPToolStructuredOutputTestTarget >> testPasses [
	"This is a fixture test method, intentionally exercised by MCP test-running tool tests."

	self assert: true
]

{ #category : 'tests' }
MCPToolStructuredOutputTestTarget >> testSkips [
	"This is a fixture test method; the skip is intentional and exercised by MCP test-running tool tests."

	self skip: 'skip probe'
]
