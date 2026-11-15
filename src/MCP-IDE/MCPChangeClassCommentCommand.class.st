"
Changes the comment of one class and answers the class.
"
Class {
	#name : 'MCPChangeClassCommentCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'classComment'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
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

{ #category : 'executing' }
MCPChangeClassCommentCommand >> execute [
	"A comment already as asked is not set again."

	| targetClass |
	targetClass := self targetClass.
	targetClass mcpComment = self classComment ifFalse: [ targetClass comment: self classComment ].
	^ targetClass
]

{ #category : 'private' }
MCPChangeClassCommentCommand >> targetClass [

	^ MCPImageLookup classNamed: self className
]
