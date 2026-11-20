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

{ #category : 'introspection' }
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

{ #category : 'private' }
MCPClassCommand >> installing: aBlock [

	^ self installing: aBlock under: self currentClass superclass
]

{ #category : 'private' }
MCPClassCommand >> installing: aBlock under: aSuperclass [
	"Pharo migrates the instances of each class it reshapes inside a block that stops any unwinding through it: an exception there reaches the handler around the call, whose answer is dropped, and Pharo goes on without installing that new class, which it has already listed among the subclasses of its superclass, aSuperclass for the class the command names. The first exception whose handling unwinds is noted, and if Pharo goes on, the subclass links are repaired once it is done and the change fails, naming the classes Pharo abandoned. Pharo reshapes the classes one at a time, so it may have changed the class the command names before abandoning a subclass, which keeps its old shape. One a handler resumes is no failure."

	| failure reshaped value |
	reshaped := self currentClass withAllSubclasses.
	value := aBlock
		         on: Exception
		         do: [ :exception | exception resume: ([ exception outer ] ifCurtailed: [ failure ifNil: [ failure := exception ] ]) ].
	failure ifNotNil: [
			| abandoned named |
			abandoned := self restoreHierarchyOf: reshaped afterAbandonedInstallUnder: aSuperclass.
			named := self currentClass name.
			Error signal: (String streamContents: [ :stream |
						 stream << 'Pharo '.
						 (abandoned includes: named) ifFalse: [ stream << 'changed ' << named << ' but ' ].
						 stream << 'abandoned installing the new ' << (', ' join: abandoned asSortedCollection) << ' after ' << failure description ]) ].
	^ value
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

{ #category : 'private' }
MCPClassCommand >> restoreHierarchyOf: someClasses afterAbandonedInstallUnder: aSuperclass [
	"Pharo took a class it abandoned out of its superclass's subclasses, and listed there the new class it did not install, which the image does not hold under its name. Answers the names of the classes Pharo abandoned."

	| abandoned |
	abandoned := Set new.
	someClasses do: [ :each | each superclass addSubclass: each ].
	{ aSuperclass } , someClasses do: [ :each |
			each subclasses do: [ :subclass |
					(MCPImageLookup holds: subclass) ifFalse: [
							each removeSubclass: subclass.
							abandoned add: subclass name ] ] ].
	^ abandoned
]
