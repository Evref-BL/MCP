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
	"A class already under the superclass asked for is not rebuilt."

	| currentClass currentSuperclassName |
	currentClass := self currentClass.
	currentSuperclassName := currentClass superclass ifNil: [ '' ] ifNotNil: [ :aSuperclass | aSuperclass name asString ].
	currentSuperclassName = self superclassName ifTrue: [ ^ currentClass ].
	(self builderForReparenting: currentClass toSuperclass: (self resolvedSuperclassNamed: self superclassName)) install.
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
