Class {
	#name : 'MCPMoveClassCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'packageName',
		'tag'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPMoveClassCommand class >> className: aClassName packageName: aPackageName tag: aTag [

	^ self new
		  className: aClassName;
		  packageName: aPackageName;
		  tag: aTag;
		  yourself
]

{ #category : 'accessing' }
MCPMoveClassCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPMoveClassCommand >> className: aString [

	className := aString
]

{ #category : 'private' }
MCPMoveClassCommand >> destinationValidation [

	| package |
	package := self ensurePackageNamed: self packageName.
	self tag ifNil: [ ^ self ].
	(package hasTag: self tag) ifFalse: [
		MCPCommandError
			signalMissingTag: self tag
			packageName: self packageName
			forClassNamed: self className ]
]

{ #category : 'private' }
MCPMoveClassCommand >> ensurePackageNamed: aPackageName [

	^ self packageOrganizer ensurePackage: aPackageName
]

{ #category : 'executing' }
MCPMoveClassCommand >> execute [

	| movedClass oldPackageName oldTag |
	movedClass := Smalltalk globals
		              at: self className asSymbol
		              ifAbsent: [
		              MCPCommandError signalMissingClassNamed:
			              self className ].
	self destinationValidation.
	oldPackageName := movedClass packageName asString.
	oldTag := movedClass packageTagName asString.
	self performMove.
	movedClass := Smalltalk globals at: self className asSymbol.
	^ MCPMoveClassResult
		  classInfo: (MCPClassInfo fromClass: movedClass)
		  oldPackageName: oldPackageName
		  oldTag: oldTag
]

{ #category : 'accessing' }
MCPMoveClassCommand >> packageName [

	^ packageName
]

{ #category : 'accessing' }
MCPMoveClassCommand >> packageName: aString [

	packageName := aString
]

{ #category : 'private' }
MCPMoveClassCommand >> performMove [

	self tag
		ifNil: [
			(RBMoveClassTransformation
				 move: self className
				 toPackage: self packageName) execute ]
		ifNotNil: [
			(RBMoveClassTransformation
				 move: self className
				 toPackage: self packageName
				 inTag: self tag) execute ]
]

{ #category : 'accessing' }
MCPMoveClassCommand >> tag [

	^ tag
]

{ #category : 'accessing' }
MCPMoveClassCommand >> tag: aString [

	tag := aString
]
