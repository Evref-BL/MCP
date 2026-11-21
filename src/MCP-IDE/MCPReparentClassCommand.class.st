"
Changes the superclass of one class and answers the class.
"
Class {
	#name : 'MCPReparentClassCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'superclassName'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReparentClassCommand class >> className: aClassName superclassName: aSuperclassName [

	^ self new
		  className: aClassName;
		  superclassName: aSuperclassName;
		  yourself
]

{ #category : 'executing' }
MCPReparentClassCommand >> execute [
	"A class already under the superclass asked for is not rebuilt. The methods at or below the class that use a variable the old superclass gave and the new one does not are named in a warning first."

	| currentClass currentSuperclassName superclass kept |
	currentClass := self currentClass.
	currentSuperclassName := currentClass superclass ifNil: [ '' ] ifNotNil: [ :aSuperclass | aSuperclass name asString ].
	currentSuperclassName = self superclassName ifTrue: [ ^ currentClass ].
	superclass := self resolvedSuperclassNamed: self superclassName.
	kept := self variablesInheritedFrom: superclass.
	self
		warnOfMethodsUsing: ((self variablesInheritedFrom: currentClass superclass) reject: [ :each | kept includes: each ])
		below: currentClass.
	self installing: [ (self builderForReparenting: currentClass toSuperclass: superclass) install ] under: superclass.
	^ self currentClass
]

{ #category : 'accessing' }
MCPReparentClassCommand >> superclassName [

	^ superclassName
]

{ #category : 'accessing' }
MCPReparentClassCommand >> superclassName: aString [

	superclassName := aString
]

{ #category : 'private' }
MCPReparentClassCommand >> variablesInheritedFrom: aSuperclass [
	"The variables a class under aSuperclass sees from it, on either side: its slots, the class variables of it and its superclasses, and the variables of the pools they read."

	| classes |
	aSuperclass ifNil: [ ^ IdentitySet new ].
	classes := aSuperclass withAllSuperclasses.
	^ (aSuperclass allSlots , aSuperclass classSide allSlots
	   , (classes flatCollect: [ :each | each classVarNames collect: [ :name | each classVariableNamed: name ] ])
	   , (aSuperclass allSharedPools flatCollect: [ :each | each classVarNames collect: [ :name | each classVariableNamed: name ] ]))
		  asIdentitySet
]
