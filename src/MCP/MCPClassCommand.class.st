"
Abstract command for operations targeting one existing or newly defined class.

Subclasses provide #className and implement their command-specific execution.
"
Class {
	#name : 'MCPClassCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'className'
	],
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

{ #category : 'accessing' }
MCPClassCommand >> layout [

	self subclassResponsibility
]

{ #category : 'private - resolving' }
MCPClassCommand >> resolvedLayoutClass [

	| behavior |
	self layout ifNil: [ ^ nil ].
	behavior := Smalltalk globals
		at: self layout asSymbol
		ifAbsent: [
			MCPCommandError
				signalErrorCode: #LayoutClassNotFound
				message: 'Layout class ' , self layout , ' does not exist.'
				details: {
					(#className -> self className).
					(#layout -> self layout) } asDictionary ].
	(AbstractLayout withAllSubclasses includes: behavior) ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidLayoutClass
			message: self layout , ' not layout class.'
			details: {
				(#className -> self className).
				(#layout -> self layout) } asDictionary ].
	^ behavior
]

{ #category : 'private - resolving' }
MCPClassCommand >> resolvedSharedPoolNamed: aSharedPoolName [

	| behavior sharedPoolName |
	sharedPoolName := aSharedPoolName.
	behavior := Smalltalk globals
		at: sharedPoolName asSymbol
		ifAbsent: [
			MCPCommandError
				signalErrorCode: #SharedPoolNotFound
				message: 'Shared pool ' , sharedPoolName , ' does not exist.'
				details: {
					(#className -> self className).
					(#sharedPoolName -> sharedPoolName) } asDictionary ].
	(SharedPool withAllSubclasses includes: behavior) ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidSharedPool
			message: sharedPoolName , ' not shared pool.'
			details: {
				(#className -> self className).
				(#sharedPoolName -> sharedPoolName) } asDictionary ].
	^ behavior
]
