"
Fixture test class that the test_run tests run among other selections.
"
Class {
	#name : 'MCPToolCoverageTargetTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolCoverageTargetTest >> testCoveredMethod [

	self assert: MCPToolCoverageTarget new coveredMethod equals: 2.
	self assert: MCPToolCoverageTarget classCoveredMethod equals: 3
]

{ #category : 'tests' }
MCPToolCoverageTargetTest >> testPartiallyCoveredMethod [

	self assert: (MCPToolCoverageTarget new partiallyCoveredMethod: 1) equals: 1
]
