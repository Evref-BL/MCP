"
Fixture test case used by test_run tests.
"
Class {
	#name : 'MCPToolRunTestsTimeLimitTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'accessing' }
MCPToolRunTestsTimeLimitTarget class >> defaultTimeLimit [

	^ 100 milliSeconds
]

{ #category : 'tests' }
MCPToolRunTestsTimeLimitTarget >> testWaitsTooLong [
	"This is a fixture test method; outlasting the class's time limit is intentional and exercised by MCP test-running tool tests."

	(Delay forSeconds: 3) wait
]
