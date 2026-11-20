"
A plain class, not a test class, for the test_run tests: one names its method to see it refused, and MCPToolCoverageTargetTest tests it.
"
Class {
	#name : 'MCPToolCoverageTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'examples' }
MCPToolCoverageTarget >> coveredMethod [

	^ 1 + 1
]

{ #category : 'examples' }
MCPToolCoverageTarget >> partiallyCoveredMethod: anInteger [

	anInteger > 0
		ifTrue: [ ^ 1 ]
		ifFalse: [ ^ 0 ]
]
