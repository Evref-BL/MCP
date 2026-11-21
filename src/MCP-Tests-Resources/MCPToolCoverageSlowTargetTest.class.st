"
A bounded wait after executing covered code, for coverage interrupted mid-test.
"
Class {
	#name : 'MCPToolCoverageSlowTargetTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolCoverageSlowTargetTest >> testCoversThenWaits [

	self assert: MCPToolCoverageTarget new coveredMethod equals: 2.
	(Delay forSeconds: 10) wait
]
