"
Result DTO for renaming a class.

It carries the updated class info and both old and new class names.
"
Class {
	#name : 'MCPRenameClassResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldClassName',
		'newClassName'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRenameClassResult class >> classInfo: aClassInfo oldClassName: anOldClassName newClassName: aNewClassName [

	^ self new
		  classInfo: aClassInfo;
		  oldClassName: anOldClassName;
		  newClassName: aNewClassName;
		  yourself
]

{ #category : 'converting' }
MCPRenameClassResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldClassName put: self oldClassName.
	data at: #newClassName put: self newClassName.
	^ data
]

{ #category : 'accessing' }
MCPRenameClassResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPRenameClassResult >> classInfo: anObject [

	classInfo := anObject
]

{ #category : 'accessing' }
MCPRenameClassResult >> newClassName [

	^ newClassName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRenameClassResult >> newClassName: aString [

	newClassName := aString ifNil: [ '' ] ifNotNil: [ aString ]
]

{ #category : 'accessing' }
MCPRenameClassResult >> oldClassName [

	^ oldClassName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRenameClassResult >> oldClassName: aString [

	oldClassName := aString ifNil: [ '' ] ifNotNil: [ aString ]
]
