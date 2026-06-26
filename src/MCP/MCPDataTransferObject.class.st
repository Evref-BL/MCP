"
Abstract base for MCP value objects that can be rendered as compact dictionaries.

Subclasses implement #asDictionary.
"
Class {
	#name : 'MCPDataTransferObject',
	#superclass : 'Object',
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'testing' }
MCPDataTransferObject class >> isAbstract [

	^ self == MCPDataTransferObject
]

{ #category : 'converting' }
MCPDataTransferObject >> asDictionary [

	self subclassResponsibility
]
