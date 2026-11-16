"
Moves a class to another package and/or tag and answers the class.

Given the package the class is already in and a tag, it retags the class inside its package.
"
Class {
	#name : 'MCPMoveClassCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'packageName',
		'tag'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPMoveClassCommand class >> className: aClassName packageName: aPackageName tag: aTag [

	^ self new
		  className: aClassName;
		  packageName: aPackageName;
		  tag: aTag;
		  yourself
]

{ #category : 'private' }
MCPMoveClassCommand >> destinationValidation [

	| package |
	package := self ensurePackageNamed: self packageName.
	self tag ifNotNil: [ package ensureTag: self tag ]
]

{ #category : 'private' }
MCPMoveClassCommand >> ensurePackageNamed: aPackageName [

	^ self packageOrganizer ensurePackage: aPackageName
]

{ #category : 'executing' }
MCPMoveClassCommand >> execute [

	MCPImageLookup classNamed: self className.
	self destinationValidation.
	self performMove.
	^ Smalltalk globals at: self className asSymbol
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
		ifNil: [ (RBMoveClassTransformation move: self className toPackage: self packageName) execute ]
		ifNotNil: [ (RBMoveClassTransformation move: self className toPackage: self packageName inTag: self tag) execute ]
]

{ #category : 'accessing' }
MCPMoveClassCommand >> tag [

	^ tag
]

{ #category : 'accessing' }
MCPMoveClassCommand >> tag: aString [

	tag := aString
]
