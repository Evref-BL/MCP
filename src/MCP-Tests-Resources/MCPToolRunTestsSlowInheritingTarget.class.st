"
Fixture test case that inherits a test and adds a slow one.
"
Class {
	#name : 'MCPToolRunTestsSlowInheritingTarget',
	#superclass : 'MCPToolRunTestsAbstractTarget',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolRunTestsSlowInheritingTarget >> testWaits [
	"This is a fixture test method; the delay is intentional and exercised by MCP test-running timeout tests."

	(Delay forMilliseconds: 500) wait
]
