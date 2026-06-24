"
Abstract base for command objects that perform one image-side action through #execute.

Subclasses keep the command-specific state and implement #execute.
"
Class {
	#name : 'MCPCommand',
	#superclass : 'Object',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPCommand class >> isAbstract [

	^ self == MCPCommand
]

{ #category : 'executing' }
MCPCommand >> execute [

	self subclassResponsibility
]
