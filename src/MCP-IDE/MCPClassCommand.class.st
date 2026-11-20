"
Abstract operation on one class, existing or about to be made, named by className.

Executing it answers the class as it is after the change.
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
MCPClassCommand >> resolvedSharedPoolsNamed: someSharedPoolNames [

	^ someSharedPoolNames
		  collect: [ :each | MCPImageLookup classNamed: each role: #sharedPool details: { (#class -> self className) } ]
		  as: Array
]

{ #category : 'private - resolving' }
MCPClassCommand >> resolvedSuperclassNamed: aSuperclassName [

	^ MCPImageLookup classNamed: aSuperclassName role: #superclass details: { (#class -> self className) }
]

{ #category : 'private - resolving' }
MCPClassCommand >> resolvedTraitsNamed: someTraitNames [

	^ someTraitNames
		  collect: [ :each |
				  MCPImageLookup traitNamed: each details: {
						  (#class -> self className).
						  (#traits -> someTraitNames) } ]
		  as: Array
]
