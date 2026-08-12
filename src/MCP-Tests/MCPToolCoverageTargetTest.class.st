"
SUnit tests for MCPToolCoverageTarget used to exercise MCP coverage reporting.
"
Class {
	#name : 'MCPToolCoverageTargetTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'tests' }
MCPToolCoverageTargetTest >> testCoveredMethod [

	self assert: MCPToolCoverageTarget new coveredMethod equals: 2
]

{ #category : 'tests' }
MCPToolCoverageTargetTest >> testPartiallyCoveredMethod [

	self assert: (MCPToolCoverageTarget new partiallyCoveredMethod: 1) equals: 1
]
