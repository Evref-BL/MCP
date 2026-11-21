"
A plain class for test selection and scoped coverage fixtures.
"
Class {
	#name : 'MCPToolCoverageTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'examples' }
MCPToolCoverageTarget class >> classCoveredMethod [

	^ 3
]

{ #category : 'examples' }
MCPToolCoverageTarget >> abstractMethod [

	self subclassResponsibility
]

{ #category : 'examples' }
MCPToolCoverageTarget >> coveredMethod [

	^ 1 + 1
]

{ #category : 'examples' }
MCPToolCoverageTarget >> ignoredMethod [

	<ignoreForCoverage>
	^ 4
]

{ #category : 'examples' }
MCPToolCoverageTarget >> partiallyCoveredMethod: anInteger [

	anInteger > 0
		ifTrue: [ ^ 1 ]
		ifFalse: [ ^ 0 ]
]

{ #category : 'examples' }
MCPToolCoverageTarget >> uncoveredMethod [

	^ 5
]
