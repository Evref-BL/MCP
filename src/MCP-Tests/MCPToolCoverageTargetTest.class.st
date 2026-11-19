"
Fixture test class that the test_run tests run among other selections.
"
Class {
	#name : 'MCPToolCoverageTargetTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolCoverageTargetTest >> testCoveredMethod [

	self assert: MCPToolCoverageTarget new coveredMethod equals: 2
]

{ #category : 'tests' }
MCPToolCoverageTargetTest >> testPartiallyCoveredMethod [

	self assert: (MCPToolCoverageTarget new partiallyCoveredMethod: 1) equals: 1
]
