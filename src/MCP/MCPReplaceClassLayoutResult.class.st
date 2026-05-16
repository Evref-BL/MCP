"
Result DTO for replacing the layout of a class. It carries the class state after replacement and the old/new layout class names for edit-class update output.
"
Class {
	#name : 'MCPReplaceClassLayoutResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldLayoutClassName',
		'newLayoutClassName'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPReplaceClassLayoutResult class >> classInfo: aClassInfo oldLayoutClassName: oldName newLayoutClassName: newName [

	^ self new
		  classInfo: aClassInfo;
		  oldLayoutClassName: oldName;
		  newLayoutClassName: newName;
		  yourself
]

{ #category : 'converting' }
MCPReplaceClassLayoutResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldLayoutClassName put: self oldLayoutClassName.
	data at: #newLayoutClassName put: self newLayoutClassName.
	^ data
]

{ #category : 'accessing' }
MCPReplaceClassLayoutResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPReplaceClassLayoutResult >> classInfo: aClassInfo [

	classInfo := aClassInfo
]

{ #category : 'accessing' }
MCPReplaceClassLayoutResult >> newLayoutClassName [

	^ newLayoutClassName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPReplaceClassLayoutResult >> newLayoutClassName: aString [

	newLayoutClassName := aString ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPReplaceClassLayoutResult >> oldLayoutClassName [

	^ oldLayoutClassName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPReplaceClassLayoutResult >> oldLayoutClassName: aString [

	oldLayoutClassName := aString ifNil: [ '' ]
]
