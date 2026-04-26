"
Command that renames a class using the refactoring engine.

It preserves the old class name for reporting and returns the renamed class metadata in MCPRenameClassResult.
"
Class {
	#name : 'MCPRenameClassCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'newClassName',
		'model'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRenameClassCommand class >> className: aClassName newClassName: aNewClassName [

	^ self new
		  className: aClassName;
		  newClassName: aNewClassName;
		  yourself
]

{ #category : 'instance creation' }
MCPRenameClassCommand class >> className: aClassName newClassName: aNewClassName model: aModel [

	^ self new
		  className: aClassName;
		  newClassName: aNewClassName;
		  model: aModel;
		  yourself
]

{ #category : 'accessing' }
MCPRenameClassCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPRenameClassCommand >> className: aString [

	className := aString
]

{ #category : 'executing' }
MCPRenameClassCommand >> execute [

	| renamedClass |
	Smalltalk globals
		at: self className asSymbol
		ifAbsent: [ MCPCommandError signalMissingClassNamed: self className ].
	self refactoring execute.
	renamedClass := Smalltalk globals at: self newClassName asSymbol.
	^ MCPRenameClassResult
		  classInfo: (MCPClassInfo fromClass: renamedClass)
		  oldClassName: self className
		  newClassName: self newClassName
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
		  ifNil: [
			  ReRenameClassRefactoring
				  rename: self className
				  to: self newClassName ]
		  ifNotNil: [
			  ReRenameClassRefactoring
				  model: self model
				  rename: self className
				  to: self newClassName ]
]
