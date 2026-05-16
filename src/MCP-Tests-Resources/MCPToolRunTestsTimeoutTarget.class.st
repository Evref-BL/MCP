"
Test fixture used by run-tests timeout coverage.
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

	(Delay forMilliseconds: 2000) wait.
	self assert: true
]
