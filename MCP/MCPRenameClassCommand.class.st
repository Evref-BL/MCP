Class {
	#name : 'MCPRenameClassCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'newClassName'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPRenameClassCommand class >> className: aClassName newClassName: aNewClassName [

	^ self new
		  className: aClassName;
		  newClassName: aNewClassName;
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
	(ReRenameClassRefactoring
		 rename: self className
		 to: self newClassName) execute.
	renamedClass := Smalltalk globals at: self newClassName asSymbol.
	^ MCPRenameClassResult
		  classInfo: (MCPClassInfo fromClass: renamedClass)
		  oldClassName: self className
		  newClassName: self newClassName
]

{ #category : 'accessing' }
MCPRenameClassCommand >> newClassName [

	^ newClassName
]

{ #category : 'accessing' }
MCPRenameClassCommand >> newClassName: aString [

	newClassName := aString
]
