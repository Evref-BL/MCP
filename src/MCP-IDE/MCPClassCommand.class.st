"
Abstract command for operations targeting one existing or newly defined class.

Subclasses provide #class and implement their command-specific execution.
"
Class {
	#name : 'MCPClassCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'className'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPClassCommand class >> isAbstract [

	^ self == MCPClassCommand
]

{ #category : 'accessing' }
MCPClassCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPClassCommand >> className: aClassName [

	className := aClassName
]

{ #category : 'private' }
MCPClassCommand >> currentClass [

	^ MCPImageLookup classNamed: self className
]

{ #category : 'private - resolving' }
MCPClassCommand >> resolvedLayoutClassNamed: layoutName [

	layoutName ifNil: [ ^ nil ].
	^ MCPImageLookup classNamed: layoutName role: #layoutClass details: { (#class -> self className) }
]

{ #category : 'private - resolving' }
MCPClassCommand >> resolvedSharedPoolNamed: aSharedPoolName [

	^ MCPImageLookup classNamed: aSharedPoolName role: #sharedPool details: { (#class -> self className) }
]
