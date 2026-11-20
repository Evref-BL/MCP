"
Renames a class using the refactoring engine, which updates every reference to it, and answers the renamed class.
"
Class {
	#name : 'MCPRenameClassCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'newClassName'
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

	self currentClass.
	(ReRenameClassRefactoring rename: self className to: self newClassName) execute.
	^ self class environment at: self newClassName asSymbol
]

{ #category : 'accessing' }
MCPRenameClassCommand >> newClassName [

	^ newClassName
]

{ #category : 'accessing' }
MCPRenameClassCommand >> newClassName: aString [

	newClassName := aString
]
