"
Small production-like target used by MCP test_run coverage tests.

Its methods are intentionally simple and stable so coverage assertions can distinguish fully covered, uncovered, and partially covered methods.
"
Class {
	#name : 'MCPToolCoverageTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources-Internal',
	#package : 'MCP-Tests-Resources',
	#tag : 'Internal'
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

{ #category : 'examples' }
MCPToolCoverageTarget >> uncoveredMethod [

	^ 2
]
