Class {
	#name : 'MCPChangeClassCommentResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldClassComment',
		'newClassComment'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPChangeClassCommentResult class >> classInfo: aClassInfo oldClassComment: anOldClassComment newClassComment: aNewClassComment [

	^ self new
		  classInfo: aClassInfo;
		  oldClassComment: anOldClassComment;
		  newClassComment: aNewClassComment;
		  yourself
]

{ #category : 'converting' }
MCPChangeClassCommentResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldClassComment put: self oldClassComment.
	data at: #newClassComment put: self newClassComment.
	^ data
]

{ #category : 'accessing' }
MCPChangeClassCommentResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPChangeClassCommentResult >> classInfo: anObject [

	classInfo := anObject
]

{ #category : 'accessing' }
MCPChangeClassCommentResult >> newClassComment [

	^ newClassComment ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPChangeClassCommentResult >> newClassComment: aString [

	newClassComment := aString ifNil: [ '' ] ifNotNil: [ aString ]
]

{ #category : 'accessing' }
MCPChangeClassCommentResult >> oldClassComment [

	^ oldClassComment ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPChangeClassCommentResult >> oldClassComment: aString [

	oldClassComment := aString ifNil: [ '' ] ifNotNil: [ aString ]
]
