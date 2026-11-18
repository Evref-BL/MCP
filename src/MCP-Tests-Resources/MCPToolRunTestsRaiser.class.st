"
Fixture class whose methods raise or wait on purpose, so test_run tests can see where an issue came from.
"
Class {
	#name : 'MCPToolRunTestsRaiser',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'raising' }
MCPToolRunTestsRaiser >> addToNil [
	"This is a fixture method; sending + to nil is intentional and exercised by MCP test-running tool tests."

	^ nil + 1
]

{ #category : 'raising' }
MCPToolRunTestsRaiser >> compareWithNil [
	"This is a fixture method; comparing with nil is intentional and exercised by MCP test-running tool tests."

	#( 1 ) do: [ :each | each > nil ]
]

{ #category : 'raising' }
MCPToolRunTestsRaiser >> fail [
	"This is a fixture method; the error is intentional and exercised by MCP test-running tool tests."

	Error signal: 'fixture broken'
]

{ #category : 'waiting' }
MCPToolRunTestsRaiser >> waitHalfASecond [
	"This is a fixture method; the delay is intentional and exercised by MCP test-running timeout tests."

	(Delay forMilliseconds: 500) wait
]
