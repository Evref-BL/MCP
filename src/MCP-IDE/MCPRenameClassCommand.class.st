"
Renames a class using the refactoring engine, which updates every reference to it, and answers the renamed class.
"
Class {
	#name : 'MCPRenameClassCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'newClassName',
		'model'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRenameClassCommand class >> className: aClassName newClassName: aNewClassName [

	^ self new
		  className: aClassName;
		  newClassName: aNewClassName;
		  yourself
]

{ #category : 'executing' }
MCPRenameClassCommand >> execute [

	MCPImageLookup classNamed: self className.
	self refactoring execute.
	^ Smalltalk globals at: self newClassName asSymbol
]

{ #category : 'accessing' }
MCPRenameClassCommand >> model [

	^ model
]

{ #category : 'accessing' }
MCPRenameClassCommand >> model: aModel [

	model := aModel
]

{ #category : 'accessing' }
MCPRenameClassCommand >> newClassName [

	^ newClassName
]

{ #category : 'accessing' }
MCPRenameClassCommand >> newClassName: aString [

	newClassName := aString
]

{ #category : 'private' }
MCPRenameClassCommand >> refactoring [

	^ self model
		  ifNil: [ ReRenameClassRefactoring rename: self className to: self newClassName ]
		  ifNotNil: [ ReRenameClassRefactoring model: self model rename: self className to: self newClassName ]
]
