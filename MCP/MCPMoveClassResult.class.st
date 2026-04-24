Class {
	#name : 'MCPMoveClassResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldPackageName',
		'oldTag'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPMoveClassResult class >> classInfo: aClassInfo oldPackageName: anOldPackageName oldTag: anOldTag [

	^ self new
		  classInfo: aClassInfo;
		  oldPackageName: anOldPackageName;
		  oldTag: anOldTag;
		  yourself
]

{ #category : 'converting' }
MCPMoveClassResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldPackageName put: self oldPackageName.
	data at: #oldTag put: self oldTag.
	^ data
]

{ #category : 'accessing' }
MCPMoveClassResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPMoveClassResult >> classInfo: anObject [

	classInfo := anObject
]

{ #category : 'accessing' }
MCPMoveClassResult >> oldPackageName [

	^ oldPackageName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPMoveClassResult >> oldPackageName: aString [

	oldPackageName := aString ifNil: [ '' ] ifNotNil: [ aString ]
]

{ #category : 'accessing' }
MCPMoveClassResult >> oldTag [

	^ oldTag ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPMoveClassResult >> oldTag: aString [

	oldTag := aString ifNil: [ '' ] ifNotNil: [ aString ]
]
