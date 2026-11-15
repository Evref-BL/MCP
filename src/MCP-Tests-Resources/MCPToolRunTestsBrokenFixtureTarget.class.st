"
Fixture test case used by test_run tests.
"
Class {
	#name : 'MCPToolRunTestsBrokenFixtureTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'running' }
MCPToolRunTestsBrokenFixtureTarget >> setUp [
	"This is a fixture method; the missing selector is intentional and exercised by MCP test-running tool tests."

	super setUp.
	nil mcpNoSuchFixtureSelector
]

{ #category : 'running' }
MCPToolRunTestsBrokenFixtureTarget >> tearDown [
	"This is a fixture method; the missing selector is intentional and exercised by MCP test-running tool tests."

	nil mcpNoSuchFixtureSelector.
	super tearDown
]

{ #category : 'tests' }
MCPToolRunTestsBrokenFixtureTarget >> testOne [
	"This is a fixture test method, intentionally exercised by MCP test-running tool tests."

	self assert: true
]

{ #category : 'tests' }
MCPToolRunTestsBrokenFixtureTarget >> testTwo [
	"This is a fixture test method, intentionally exercised by MCP test-running tool tests."

	self assert: true
]
