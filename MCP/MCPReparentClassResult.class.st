Class {
	#name : 'MCPReparentClassResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldSuperclassName'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPReparentClassResult class >> classInfo: aClassInfo oldSuperclassName: anOldSuperclassName [

	^ self new
		  classInfo: aClassInfo;
		  oldSuperclassName: anOldSuperclassName;
		  yourself
]

{ #category : 'converting' }
MCPReparentClassResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldSuperclassName put: self oldSuperclassName.
	^ data
]

{ #category : 'accessing' }
MCPReparentClassResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPReparentClassResult >> classInfo: anObject [

	classInfo := anObject
]

{ #category : 'accessing' }
MCPReparentClassResult >> oldSuperclassName [

	^ oldSuperclassName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPReparentClassResult >> oldSuperclassName: aString [

	oldSuperclassName := aString ifNil: [ '' ] ifNotNil: [ aString ]
]
