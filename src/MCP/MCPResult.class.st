"
Abstract base for MCP result objects.

Dictionary-style results implement #asDictionary.
"
Class {
	#name : 'MCPResult',
	#superclass : 'Object',
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'testing' }
MCPResult class >> isAbstract [

	^ self == MCPResult
]

{ #category : 'converting' }
MCPResult >> asDictionary [

	self subclassResponsibility
]
