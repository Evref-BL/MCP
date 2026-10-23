"
Fixture class with several methods, so that batch tests can name more than one target.
"
Class {
	#name : 'MCPToolBatchTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'reading' }
MCPToolBatchTestTarget >> readFirst [

	^ 'first'
]

{ #category : 'reading' }
MCPToolBatchTestTarget >> readSecond [

	^ 'second'
]
