"
Command that changes the class comment of one class.

It records the previous comment and returns an MCPChangeClassCommentResult so edit-class can report exactly what changed.
"
Class {
	#name : 'MCPChangeClassCommentCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classComment'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPChangeClassCommentCommand class >> className: aClassName classComment: aClassComment [

	^ self new
		  className: aClassName;
		  classComment: aClassComment;
		  yourself
]

{ #category : 'accessing' }
MCPChangeClassCommentCommand >> classComment [

	^ classComment ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPChangeClassCommentCommand >> classComment: aString [

	classComment := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
MCPChangeClassCommentCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPChangeClassCommentCommand >> className: aString [

	className := aString
]

{ #category : 'executing' }
MCPChangeClassCommentCommand >> execute [

	| oldClassComment targetClass updatedClass |
	targetClass := self targetClass.
	oldClassComment := targetClass comment.
	oldClassComment = self classComment ifTrue: [
		^ MCPChangeClassCommentResult
			  classInfo: (MCPClassInfo fromClass: targetClass)
			  oldClassComment: oldClassComment
			  newClassComment: oldClassComment ].
	targetClass comment: self classComment.
	updatedClass := Smalltalk globals at: self className asSymbol.
	^ MCPChangeClassCommentResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  oldClassComment: oldClassComment
		  newClassComment: updatedClass comment
]

{ #category : 'private' }
MCPChangeClassCommentCommand >> targetClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]
