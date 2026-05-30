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

	self assert: true
]

{ #category : 'tests' }
MCPToolRunTestsTimeoutTarget >> testSlowPass [

	(Delay forMilliseconds: 300) wait.
	self assert: true
]
