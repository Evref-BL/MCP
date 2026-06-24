"
Abstract command for operations targeting one existing or newly defined class.

Subclasses provide #className and implement their command-specific execution.
"
Class {
	#name : 'MCPClassCommand',
	#superclass : 'MCPCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPClassCommand class >> isAbstract [

	^ self == MCPClassCommand
]

{ #category : 'accessing' }
MCPClassCommand >> className [

	self subclassResponsibility
]

{ #category : 'private' }
MCPClassCommand >> currentClass [

	^ MCPImageLookup classNamed: self className
]
