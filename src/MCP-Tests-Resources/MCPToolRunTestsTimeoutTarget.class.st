"
Test fixture used by test_run timeout coverage.
"
Class {
	#name : 'MCPToolRunTestsTimeoutTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolRunTestsTimeoutTarget >> testFastPass [
	"This is a fixture test method, intentionally exercised by MCP test-running tool tests."

	self assert: true
]

{ #category : 'tests' }
MCPToolRunTestsTimeoutTarget >> testSlowPass [
	"This is a fixture test method; the delay is intentional and exercised by MCP test-running timeout tests."

	(Delay forMilliseconds: 300) wait.
	self assert: true
]
