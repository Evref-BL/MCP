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

{ #category : 'private - resolving' }
MCPClassCommand >> resolvedLayoutClassNamed: layoutName [

	| behavior |
	layoutName ifNil: [ ^ nil ].
	behavior := Smalltalk globals
		at: layoutName asSymbol
		ifAbsent: [
			MCPCommandError
				signalErrorCode: #LayoutClassNotFound
				message: 'Layout class ' , layoutName , ' does not exist.'
				details: {
					(#className -> self className).
					(#layout -> layoutName) } asDictionary ].
	(AbstractLayout withAllSubclasses includes: behavior) ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidLayoutClass
			message: layoutName , ' not layout class.'
			details: {
				(#className -> self className).
				(#layout -> layoutName) } asDictionary ].
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
